# frozen_string_literal: true

module Spree
  module PaymentMethodsHelper
    def payment_method(payment)
      # hack to allow us to retrieve the name of a "deleted" payment method
      id = payment.payment_method_id
      return if id.nil?

      Spree::PaymentMethod.find_with_destroyed(id)
    end

    def payment_method_name(payment)
      payment_method(payment)&.name
    end
  end
end
