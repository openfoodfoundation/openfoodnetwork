# frozen_string_literal: true

require "taler"

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
        order = options.fetch(:order)
        payment = load_payment(order)

        payment.source ||= self
        payment.response_code ||= create_taler_order(payment)
        payment.redirect_auth_url ||= fetch_order_url(payment)
        payment.save! if payment.changed?

        payment.redirect_auth_url
      end

      # Main method called by Spree::Payment::Processing during checkout
      # when the user is redirected back to the app.
      #
      # The payment has already been made and we need to verify the success.
      def purchase(_money, _source, gateway_options)
        payment = gateway_options[:payment]

        return unless payment.response_code

        taler_order = client.fetch_order(payment.response_code)
        status = taler_order["order_status"]
        success = (status == "paid")
        message = I18n.t(status, default: status, scope: "taler.order_status")

        ActiveMerchant::Billing::Response.new(success, message)
      end

      private

      def load_payment(order)
        order.payments.checkout.where(payment_method: self).last
      end

      def create_taler_order(payment)
        # We are ignoring currency for now so that we can test with the
        # current demo backend only working with the KUDOS currency.
        taler_amount = "KUDOS:#{payment.amount}"
        urls = Rails.application.routes.url_helpers
        new_order = client.create_order(
          taler_amount,
          I18n.t("payment_method_taler.order_summary"),
          urls.payment_gateways_confirm_taler_url(payment_id: payment.id),
        )

        new_order["order_id"]
      end

      def fetch_order_url(payment)
        order = client.fetch_order(payment.response_code)
        order["order_status_url"]
      end

      def client
        @client ||= ::Taler::Client.new(preferred_backend_url, preferred_api_key)
      end
    end
  end
end
