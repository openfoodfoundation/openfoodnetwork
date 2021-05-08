# frozen_string_literal: true

module Spree
  class Payment < ApplicationRecord
    include Spree::Payment::Processing
    extend Spree::LocalizedNumber

    localize_number :amount

    IDENTIFIER_CHARS = (('A'..'Z').to_a + ('0'..'9').to_a - %w(0 1 I O)).freeze

    delegate :line_items, to: :order
    delegate :currency, to: :order

    belongs_to :order, class_name: 'Spree::Order'
    belongs_to :source, polymorphic: true
    belongs_to :payment_method, class_name: 'Spree::PaymentMethod'

    has_many :offsets, -> { where("source_type = 'Spree::Payment' AND amount < 0").completed },
             class_name: "Spree::Payment", foreign_key: :source_id
    has_many :log_entries, as: :source, dependent: :destroy

    has_one :adjustment, as: :adjustable, dependent: :destroy

    validate :validate_source
    before_create :set_unique_identifier

    after_save :create_payment_profile, if: :profiles_supported?

    # update the order totals, etc.
    after_save :ensure_correct_adjustment, :update_order
    # invalidate previously entered payments
    after_create :invalidate_old_payments

    # Skips the validation of the source (for example, credit card) of the payment.
    #
    # This is used in refunds as the validation of the card can fail but the refund can go through,
    #    we trust the payment gateway in these cases. For example, Stripe is accepting refunds with
    #    source cards that were valid when the payment was placed but are now expired, and we
    #    consider them invalid.
    attr_accessor :skip_source_validation
    attr_accessor :source_attributes

    after_initialize :build_source

    scope :from_credit_card, -> { where(source_type: 'Spree::CreditCard') }
    scope :with_state, ->(s) { where(state: s.to_s) }
    scope :completed, -> { with_state('completed') }
    scope :pending, -> { with_state('pending') }
    scope :failed, -> { with_state('failed') }
    scope :valid, -> { where('state NOT IN (?)', %w(failed invalid)) }
    scope :authorization_action_required, -> { where.not(cvv_response_message: nil) }

    # order state machine (see http://github.com/pluginaweek/state_machine/tree/master for details)
    state_machine initial: :checkout do
      # With card payments, happens before purchase or authorization happens
      event :started_processing do
        transition from: [:checkout, :pending, :completed, :processing], to: :processing
      end
      # When processing during checkout fails
      event :failure do
        transition from: [:pending, :processing], to: :failed
      end
      # With card payments this represents authorizing the payment
      event :pend do
        transition from: [:checkout, :processing], to: :pending
      end
      # With card payments this represents completing a purchase or capture transaction
      event :complete do
        transition from: [:processing, :pending, :checkout], to: :completed
      end
      event :void do
        transition from: [:pending, :completed, :checkout], to: :void
      end
      # when the card brand isnt supported
      event :invalidate do
        transition from: [:checkout], to: :invalid
      end
    end

    def money
      Spree::Money.new(amount, currency: currency)
    end
    alias display_amount money

    def offsets_total
      offsets.pluck(:amount).sum
    end

    def credit_allowed
      amount - offsets_total
    end

    def can_credit?
      credit_allowed.positive?
    end

    def build_source
      return if source_attributes.nil?
      return unless payment_method.andand.payment_source_class

      self.source = payment_method.payment_source_class.new(source_attributes)
      source.payment_method_id = payment_method.id
      source.user_id = order.user_id if order
    end

    def actions
      return [] unless payment_source&.respond_to?(:actions)

      actions = payment_source.actions.select do |action|
        !payment_source.respond_to?("can_#{action}?") ||
          payment_source.__send__("can_#{action}?", self)
      end

      actions
    end

    def resend_authorization_email!
      return unless authorization_action_required?

      PaymentMailer.authorize_payment(self).deliver_later
    end

    def payment_source
      res = source.is_a?(Payment) ? source.source : source
      res || payment_method
    end

    def ensure_correct_adjustment
      revoke_adjustment_eligibility if ['failed', 'invalid'].include?(state)
      return if adjustment.try(:finalized?)

      if adjustment
        adjustment.originator = payment_method
        adjustment.label = adjustment_label
        adjustment.save
      else
        payment_method.create_adjustment(adjustment_label, self, true)
        adjustment.reload
      end
    end

    def adjustment_label
      I18n.t('payment_method_fee')
    end

    def mark_as_processed
      update_attribute(:cvv_response_message, nil)
    end

    private

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
        source.errors.each do |field, error|
          field_name = I18n.t("activerecord.attributes.#{source.class.to_s.underscore}.#{field}")
          errors.add(Spree.t(source.class.to_s.demodulize.underscore), "#{field_name} #{error}")
        end
      end
      errors.blank?
    end

    def profiles_supported?
      payment_method.respond_to?(:payment_profiles_supported?) &&
        payment_method.payment_profiles_supported?
    end

    def create_payment_profile
      return unless source.is_a?(CreditCard)
      return unless source.try(:save_requested_by_customer?)
      return unless source.number || source.gateway_payment_profile_id
      return unless source.gateway_customer_profile_id.nil?

      payment_method.create_profile(self)
    rescue ActiveMerchant::ConnectionError => e
      gateway_error e
    end

    # Makes newly entered payments invalidate previously entered payments so the most recent payment
    # is used by the gateway.
    def invalidate_old_payments
      order.payments.with_state('checkout').where.not(id: id).each do |payment|
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
      order.update!
    end

    # Necessary because some payment gateways will refuse payments with
    # duplicate IDs. We *were* using the Order number, but that's set once and
    # is unchanging. What we need is a unique identifier on a per-payment basis,
    # and this is it. Related to #1998.
    # See https://github.com/spree/spree/issues/1998#issuecomment-12869105
    def set_unique_identifier
      self.identifier = generate_identifier while self.class.exists?(identifier: identifier)
    end

    def generate_identifier
      Array.new(8){ IDENTIFIER_CHARS.sample }.join
    end
  end
end
