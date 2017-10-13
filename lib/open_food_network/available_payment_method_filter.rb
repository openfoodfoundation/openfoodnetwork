module OpenFoodNetwork
  class AvailablePaymentMethodFilter
    def filter!(payment_methods)
      if stripe_enabled?
        payment_methods.reject!{ |p| p.type.ends_with?("StripeConnect") && stripe_configuration_incomplete?(p) }
      else
        payment_methods.reject!{ |p| p.type.ends_with?("StripeConnect") }
      end
    end

    private

    def stripe_enabled?
      Spree::Config.stripe_connect_enabled && Stripe.publishable_key
    end

    def stripe_configuration_incomplete?(payment_method)
      return true if payment_method.preferred_enterprise_id.zero?

      payment_method.stripe_account_id.blank?
    end
  end
end
