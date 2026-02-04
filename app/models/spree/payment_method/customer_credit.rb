# frozen_string_literal: true

module Spree
  class PaymentMethod
    class CustomerCredit < Spree::PaymentMethod
      def method_type
        "check" # empty view
      end
    end
  end
end
