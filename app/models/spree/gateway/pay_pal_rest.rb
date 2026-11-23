# frozen_string_literal: true

module Spree
  class Gateway
    class PayPalRest < Gateway
      preference :client_id, :string
      preference :client_secret, :password
      preference :server, :string, default: "sandbox"
      preference :solution, :string, default: "Mark"

      def provider_class
        PaypalRest::Provider
      end

      def provider
        @provider ||= provider_class.new(options)
      end

      def external_gateway?
        true
      end

      def external_payment_url(_options)
        Rails.application.routes.url_helpers.
          payment_gateways_paypal_rest_path(payment_method_id: id)
      end

      def supports?(_source)
        true
      end

      def method_type
        'paypal_rest'
      end

      def payment_source_class
        Spree::PaypalRestCheckout
      end

      def actions
        []
      end
    end
  end
end
