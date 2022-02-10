# frozen_string_literal: true

# Provides the redirect path if a redirect to the payment gateway is needed
module Checkout
  class StripeRedirect
    include Rails.application.routes.url_helpers

    def initialize(payment_method, order)
      @payment_method = payment_method
      @order = order
    end

    # Starts the payment process and returns the external URL if a redirect is needed
    def path
      return unless stripe_payment_method?

      payment = payment_authorizer.call!(checkout_return_url)

      return if order.errors.any?

      stripe_payment_url(payment)
    end

    private

    attr_accessor :payment_method, :order

    def stripe_payment_method?
      payment_method.is_a?(Spree::Gateway::StripeSCA)
    end

    def payment_authorizer
      OrderManagement::Order::StripeScaPaymentAuthorize.new(order)
    end

    def checkout_return_url
      payment_gateways_confirm_stripe_url
    end

    # Stripe::AuthorizeResponsePatcher patches the Stripe authorization response
    #   so that this field stores the redirect URL. It also verifies that it is a Stripe URL.
    def stripe_payment_url(payment)
      payment.cvv_response_message
    end
  end
end
