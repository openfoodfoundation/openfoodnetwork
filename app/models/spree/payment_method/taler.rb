# frozen_string_literal: true

module Spree
  class PaymentMethod
    # GNU Taler is a distributed, open source payment system.
    # You need a hosted Taler backend server to process payments.
    #
    # For testing, you can use the official demo backend:
    #
    # - Merchant UX: https://backend.demo.taler.net
    # - Username: sandbox
    # - Password: sandbox
    #
    # Configure this payment method for testing with:
    #
    # - backend_url: https://backend.demo.taler.net/instances/sandbox
    # - api_key: sandbox
    class Taler < PaymentMethod
      preference :backend_url, :string
      preference :api_key, :password

      # Name of the view to display during checkout
      def method_type
        "check" # empty view
      end

      def external_gateway?
        true
      end

      # The backend provides this URL. It can look like this:
      # https://backend.demo.taler.net/instances/blog/orders/2026..?token=S8Y..&session_id=b0b..
      def external_payment_url(options)
        # order = options.fetch(:order)
        # Taler.create_order(backend_url, api_key, order.total, "OFN Order", "https://ofn.example.net")
      end
    end
  end
end
