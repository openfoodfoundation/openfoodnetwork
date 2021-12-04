# frozen_string_literal: true

# Provides the redirect path if a redirect to the payment gateway is needed
module Checkout
  class PaypalRedirect
    include Rails.application.routes.url_helpers

    def initialize(params)
      @params = params
    end

    # Returns the path to the Paypal Express form if a redirect is needed
    def path
      return unless @params[:order][:payments_attributes]

      payment_method_id = @params[:order][:payments_attributes].first[:payment_method_id]
      payment_method = Spree::PaymentMethod.find(payment_method_id)
      return unless payment_method.is_a?(Spree::Gateway::PayPalExpress)

      payment_gateways_paypal_express_path(payment_method_id: payment_method.id)
    end
  end
end
