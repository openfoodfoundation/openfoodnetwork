module Spree
  class Payment < ActiveRecord::Base
    include Spree::Payment::Processing
    extend Spree::LocalizedNumber

    localize_number :amount

    IDENTIFIER_CHARS = (('A'..'Z').to_a + ('0'..'9').to_a - %w(0 1 I O)).freeze

    belongs_to :order, class_name: 'Spree::Order'
    belongs_to :source, polymorphic: true
    belongs_to :payment_method, class_name: 'Spree::PaymentMethod'

    has_many :offsets, -> { where("source_type = 'Spree::Payment' AND amount < 0 AND state = 'completed'") },
      class_name: "Spree::Payment", foreign_key: :source_id
    has_many :log_entries, as: :source

    has_one :adjustment, as: :source, dependent: :destroy

    before_validation :validate_source
    before_save :set_unique_identifier

    after_save :create_payment_profile, if: :profiles_supported?

    # update the order totals, etc.
    after_save :ensure_correct_adjustment, :update_order
    # invalidate previously entered payments
    after_create :invalidate_old_payments

    attr_accessor :source_attributes
    after_initialize :build_source

    scope :from_credit_card, -> { where(source_type: 'Spree::CreditCard') }
    scope :with_state, ->(s) { where(state: s.to_s) }
    scope :completed, -> { with_state('completed') }
    scope :pending, -> { with_state('pending') }
    scope :failed, -> { with_state('failed') }
    scope :valid, -> { where('state NOT IN (?)', %w(failed invalid)) }

    after_rollback :persist_invalid

    def persist_invalid
      return unless ['failed', 'invalid'].include?(state)
      state_will_change!
      save 
    end

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

    def currency
      order.currency
    end

    def money
      Spree::Money.new(amount, { currency: currency })
    end
    alias display_amount money

    def offsets_total
      offsets.pluck(:amount).sum
    end

    def credit_allowed
      amount - offsets_total
    end

    def can_credit?
      credit_allowed > 0
    end

    # see https://github.com/spree/spree/issues/981
    #
    # Import from future Spree v.2.3.0 d470b31798f37
    def build_source
      return if source_attributes.nil?
      return unless payment_method.andand.payment_source_class

      self.source = payment_method.payment_source_class.new(source_attributes)
      source.payment_method_id = payment_method.id
      source.user_id = order.user_id if order
    end

    def actions
      return [] unless payment_source and payment_source.respond_to? :actions
      payment_source.actions.select { |action| !payment_source.respond_to?("can_#{action}?") or payment_source.send("can_#{action}?", self) }
    end

    # Pin payments lacks void and credit methods, but it does have refund
    # Here we swap credit out for refund and remove void as a possible action
    def actions_with_pin_payment_adaptations
      actions = actions_without_pin_payment_adaptations
      if payment_method.is_a? Gateway::Pin
        actions << 'refund' if actions.include? 'credit'
        actions.reject! { |a| ['credit', 'void'].include? a }
      end
      actions
    end
    alias_method_chain :actions, :pin_payment_adaptations

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
        payment_method.create_adjustment(adjustment_label, order, self, true)
        association(:adjustment).reload
      end
    end

    def adjustment_label
      I18n.t('payment_method_fee')
    end

    private

    # Don't charge fees for invalid or failed payments.
    # This is called twice for failed payments, because the persistence of the 'failed'
    # state is acheived through some trickery using an after_rollback callback on the
    # payment model. See Spree::Payment#persist_invalid
    def revoke_adjustment_eligibility
      return unless adjustment.try(:reload)
      return if adjustment.finalized?

      adjustment.update_attribute(:eligible, false)
      adjustment.finalize!
    end

    def validate_source
      if source && !source.valid?
        source.errors.each do |field, error|
          field_name = I18n.t("activerecord.attributes.#{source.class.to_s.underscore}.#{field}")
          self.errors.add(Spree.t(source.class.to_s.demodulize.underscore), "#{field_name} #{error}")
        end
      end
      return !errors.present?
    end

    def profiles_supported?
      payment_method.respond_to?(:payment_profiles_supported?) && payment_method.payment_profiles_supported?
    end

    def create_payment_profile
      return unless source.is_a?(CreditCard) && source.number && !source.has_payment_profile?
      payment_method.create_profile(self)
    rescue ActiveMerchant::ConnectionError => e
      gateway_error e
    end

    def invalidate_old_payments
      order.payments.with_state('checkout').where("id != ?", self.id).each do |payment|
        payment.invalidate!
      end
    end

    def update_order
      order.payments.reload
      order.update!
    end

    # Necessary because some payment gateways will refuse payments with
    # duplicate IDs. We *were* using the Order number, but that's set once and
    # is unchanging. What we need is a unique identifier on a per-payment basis,
    # and this is it. Related to #1998.
    # See https://github.com/spree/spree/issues/1998#issuecomment-12869105
    def set_unique_identifier
      begin
        self.identifier = generate_identifier
      end while self.class.exists?(identifier: self.identifier)
    end

    def generate_identifier
      Array.new(8){ IDENTIFIER_CHARS.sample }.join
    end
  end
end
