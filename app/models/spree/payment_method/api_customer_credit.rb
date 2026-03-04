# frozen_string_literal: true

# This payment method is not intended to be used with payment, it's used with customer account
# transaction to indicate the transaction was created via API.
module Spree
  class PaymentMethod
    class ApiCustomerCredit < Spree::PaymentMethod
      # Name and description are translatable string, to allow instances to customise them
      def name
        "api_payment_method.name"
      end

      def description
        "api_payment_method.description"
      end

      def payment_source_class
        nil
      end

      def method_type
        "check" # empty view
      end

      def source_required?
        false
      end
    end
  end
end
