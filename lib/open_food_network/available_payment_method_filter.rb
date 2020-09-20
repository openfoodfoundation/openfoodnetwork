module OpenFoodNetwork
  class AvailablePaymentMethodFilter
    def filter!(payment_methods)
      if stripe_enabled?
        payment_methods.to_a.reject! do |payment_method|
          stripe_connect?(payment_method) &&
            stripe_configuration_incomplete?(payment_method)
        end
      else
        payment_methods.to_a.reject! { |payment_method| stripe_connect?(payment_method) }
      end
    end

    private

    def stripe_enabled?
      Spree::Config.stripe_connect_enabled && Stripe.publishable_key
    end

    def stripe_connect?(payment_method)
      payment_method.type.ends_with?("StripeConnect")
    end

    def stripe_configuration_incomplete?(payment_method)
      payment_method.preferred_enterprise_id.nil? ||
        payment_method.preferred_enterprise_id.zero? ||
        payment_method.stripe_account_id.blank?
    end
  end
end
