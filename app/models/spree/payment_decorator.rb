require 'spree/localized_number'

module Spree
  Payment.class_eval do
    delegate :line_items, to: :order

    # We bypass this after_rollback callback that is setup in Spree::Payment
    # The issues the callback fixes are not experienced in OFN:
    #   if a payment fails on checkout the state "failed" is persisted correctly
    def persist_invalid; end

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
  end
end
