module Spree
  class Gateway::Pin < Gateway
    preference :api_key, :string

    attr_accessible :preferred_api_key


    def provider_class
      ActiveMerchant::Billing::PinGateway
    end

    def options_with_test_preference
      options_without_test_preference.merge(:test => self.preferred_test_mode)
    end

    alias_method_chain :options, :test_preference
  end
end
