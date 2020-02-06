# frozen_string_literal: true

# Provides the redirect path if a redirect to the payment gateway is needed
module Checkout
  class StripeRedirect
    def initialize(params, order)
      @params = params
      @order = order
    end

    # Returns the path to the authentication form if a redirect is needed
    def path
      return unless stripe_payment_method?

      payment = @order.pending_payments.last
      return unless payment&.checkout?

      authorize_response = payment.authorize!
      raise unless authorize_response && payment.pending?

      payment.cvv_response_message if url?(payment.cvv_response_message)
    end

    private

    def stripe_payment_method?
      return unless @params[:order][:payments_attributes]

      payment_method_id = @params[:order][:payments_attributes].first[:payment_method_id]
      payment_method = Spree::PaymentMethod.find(payment_method_id)
      payment_method.is_a?(Spree::Gateway::StripeSCA)
    end

    def url?(string)
      return false if string.blank?

      string.starts_with?("http")
    end
  end
end
