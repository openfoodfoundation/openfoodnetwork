module OpenFoodNetwork
  class AvailablePaymentMethodFilter
    def filter!(payment_methods)
      if stripe_enabled?
        payment_methods.reject!{ |p| p.type.ends_with?("StripeConnect") && p.preferred_enterprise_id.zero? }
      else
        payment_methods.reject!{ |p| p.type.ends_with?("StripeConnect") }
      end
    end

    private

    def stripe_enabled?
      Spree::Config.stripe_connect_enabled && Stripe.publishable_key
    end
  end
end
