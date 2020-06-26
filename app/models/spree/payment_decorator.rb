require 'spree/localized_number'

module Spree
  Payment.class_eval do
    delegate :line_items, to: :order

    has_one :adjustment, as: :source, dependent: :destroy

    # We bypass this after_rollback callback that is setup in Spree::Payment
    # The issues the callback fixes are not experienced in OFN:
    #   if a payment fails on checkout the state "failed" is persisted correctly
    def persist_invalid; end

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

    def create_payment_profile
      return unless source.is_a?(CreditCard)
      return unless source.try(:save_requested_by_customer?)
      return unless source.number || source.gateway_payment_profile_id
      return unless source.gateway_customer_profile_id.nil?

      payment_method.create_profile(self)
    rescue ActiveMerchant::ConnectionError => e
      gateway_error e
    end

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
  end
end
