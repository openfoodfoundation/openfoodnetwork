# frozen_string_literal: true

require "spree/localized_number"

module Spree
  class Payment < ApplicationRecord
    include Spree::Payment::Processing
    extend Spree::LocalizedNumber

    self.belongs_to_required_by_default = false

    localize_number :amount

    IDENTIFIER_CHARS = (('A'..'Z').to_a + ('0'..'9').to_a - %w(0 1 I O)).freeze

    delegate :line_items, to: :order
    delegate :currency, to: :order

    belongs_to :order, class_name: 'Spree::Order'
    belongs_to :source, polymorphic: true
    belongs_to :payment_method, class_name: 'Spree::PaymentMethod'

    has_many :offsets, -> { where("source_type = 'Spree::Payment' AND amount < 0").completed },
             class_name: "Spree::Payment", foreign_key: :source_id,
             inverse_of: :source,
             dependent: :restrict_with_exception
    has_many :log_entries, as: :source, dependent: :destroy

    has_one :adjustment, as: :adjustable, dependent: :destroy

    validate :validate_source
    after_initialize :build_source
    before_create :set_unique_identifier

    # invalidate previously entered payments
    after_create :invalidate_old_payments
    after_save :create_payment_profile

    # update the order totals, etc.
    after_save :ensure_correct_adjustment, :update_order

    # Skips the validation of the source (for example, credit card) of the payment.
    #
    # This is used in refunds as the validation of the card can fail but the refund can go through,
    #    we trust the payment gateway in these cases. For example, Stripe is accepting refunds with
    #    source cards that were valid when the payment was placed but are now expired, and we
    #    consider them invalid.
    attr_accessor :skip_source_validation
    attr_accessor :source_attributes

    scope :from_credit_card, -> { where(source_type: 'Spree::CreditCard') }
    scope :with_state, ->(s) { where(state: s.to_s) }
    scope :completed, -> { with_state('completed') }
    scope :incomplete, -> { where(state: %w(checkout pending requires_authorization)) }
    scope :checkout, -> { with_state('checkout') }
    scope :pending, -> { with_state('pending') }
    scope :failed, -> { with_state('failed') }
    scope :valid, -> { where.not(state: %w(failed invalid)) }
    scope :void, -> { with_state('void') }
    scope :authorization_action_required, -> { where.not(redirect_auth_url: nil) }
    scope :requires_authorization, -> { with_state("requires_authorization") }
    scope :with_payment_intent, ->(code) { where(response_code: code) }

    # order state machine (see http://github.com/pluginaweek/state_machine/tree/master for details)
    state_machine initial: :checkout do
      # With card payments, happens before purchase or authorization happens
      event :started_processing do
        transition from: [:checkout, :pending, :completed, :processing, :requires_authorization],
                   to: :processing
      end
      # When processing during checkout fails
      event :failure do
        transition from: [:pending, :processing, :requires_authorization], to: :failed
      end
      # With card payments this represents authorizing the payment
      event :pend do
        transition from: [:checkout, :processing], to: :pending
      end
      # With card payments this represents completing a purchase or capture transaction
      event :complete do
        transition from: [:processing, :pending, :checkout, :requires_authorization], to: :completed
      end
      event :void do
        transition from: [:pending, :completed, :requires_authorization, :checkout], to: :void
      end
      # when the card brand isnt supported
      event :invalidate do
        transition from: [:checkout], to: :invalid
      end
      event :require_authorization do
        transition from: [:checkout, :processing], to: :requires_authorization
      end
      event :fail_authorization do
        transition from: [:requires_authorization], to: :failed
      end
      event :complete_authorization do
        transition from: [:requires_authorization], to: :completed
      end
      event :resume do
        transition from: [:void], to: :checkout
      end

      after_transition to: :completed, do: :set_captured_at
      after_transition do |payment, transition|
        # Catch any exceptions to prevent any rollback potentially
        # preventing payment from going through
        ActiveSupport::Notifications.instrument(
          "ofn.payment_transition", payment: payment, event: transition.to
        )
      rescue StandardError => e
        Rails.logger.fatal "ActiveSupport::Notification.instrument failed params: " \
                           "<event_type:ofn.payment_transition> " \
                           "<payment_id:#{payment.id}> " \
                           "<event:#{transition.to}>"
        Alert.raise(
          e,
          metadata: {
            event_tye: "ofn.payment_transition", payment_id: payment.id, event: transition.to
          }
        )
      end
    end

    def money
      Spree::Money.new(amount, currency:)
    end
    alias display_amount money

    def offsets_total
      offsets.pluck(:amount).sum
    end

    def credit_allowed
      amount - offsets_total
    end

    def build_source
      return if source_attributes.nil?
      return unless payment_method&.payment_source_class

      self.source = payment_method.payment_source_class.new(source_attributes)
      source.payment_method_id = payment_method.id
      source.user_id = order.user_id if order
    end

    def actions
      return [] unless payment_method.respond_to?(:actions)

      payment_method.actions.select do |action|
        payment_method.__send__("can_#{action}?", self)
      end
    end

    def resend_authorization_email!
      return unless requires_authorization?

      PaymentMailer.authorize_payment(self).deliver_later
    end

    def ensure_correct_adjustment
      revoke_adjustment_eligibility if ['failed', 'invalid', 'void'].include?(state)
      return if adjustment.try(:finalized?)

      if adjustment
        adjustment.originator = payment_method
        adjustment.label = adjustment_label
        adjustment.save
      elsif !processing_refund? && payment_method.present?
        payment_method.create_adjustment(adjustment_label, self, true)
        adjustment.reload
      end
    end

    def adjustment_label
      I18n.t('payment_method_fee')
    end

    def clear_authorization_url
      update_attribute(:redirect_auth_url, nil)
    end

    private

    def processing_refund?
      amount.negative?
    end

    # Don't charge fees for invalid or failed payments.
    # This is called twice for failed payments, because the persistence of the 'failed'
    # state is acheived through some trickery using an after_rollback callback on the
    # payment model. See Spree::Payment#persist_invalid
    def revoke_adjustment_eligibility
      return unless adjustment.try(:reload)
      return if adjustment.finalized?

      adjustment.update(
        eligible: false,
        state: "finalized"
      )
    end

    def validate_source
      if source && !skip_source_validation && !source.valid?
        source.errors.each do |error|
          field_name =
            I18n.t("activerecord.attributes.#{source.class.to_s.underscore}.#{error.attribute}")
          errors.add(Spree.t(source.class.to_s.demodulize.underscore),
                     "#{field_name} #{error.message}")
        end
      end
      errors.blank?
    end

    def create_payment_profile
      return unless source.is_a?(CreditCard)
      return unless source.try(:save_requested_by_customer?)
      return unless source.number || source.gateway_payment_profile_id
      return unless source.gateway_customer_profile_id.nil?

      payment_method.try(:create_profile, self)
    rescue ActiveMerchant::ConnectionError => e
      gateway_error e
    end

    # Makes newly entered payments invalidate previously entered payments so the most recent payment
    # is used by the gateway.
    def invalidate_old_payments
      order.payments.incomplete.where.not(id:).each do |payment|
        # Using update_column skips validations and so it skips validate_source. As we are just
        # invalidating past payments here, we don't want to validate all of them at this stage.
        payment.update_columns(
          state: 'invalid',
          updated_at: Time.zone.now
        )
        payment.ensure_correct_adjustment
      end
    end

    def update_order
      OrderManagement::Order::Updater.new(order).after_payment_update(self)
    end

    def set_captured_at
      update_column(:captured_at, Time.zone.now)
    end

    # Necessary because some payment gateways will refuse payments with
    # duplicate IDs. We *were* using the Order number, but that's set once and
    # is unchanging. What we need is a unique identifier on a per-payment basis,
    # and this is it. Related to #1998.
    # See https://github.com/spree/spree/issues/1998#issuecomment-12869105
    def set_unique_identifier
      self.identifier = generate_identifier while self.class.where(identifier:).exists?
    end

    def generate_identifier
      Array.new(8){ IDENTIFIER_CHARS.sample }.join
    end
  end
end
