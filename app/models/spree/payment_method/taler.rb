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

      def actions
        %w{void}
      end

      def can_void?(payment)
        payment.state == "completed"
      end

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
        payment.save! if payment.changed?

        taler_order.status_url
      end

      # Main method called by Spree::Payment::Processing during checkout
      # when the user is redirected back to the app.
      #
      # The payment has already been made and we need to verify the success.
      def purchase(_money, _source, gateway_options)
        payment = gateway_options[:payment]

        return unless payment.response_code

        taler_order = taler_order(id: payment.response_code)
        status = taler_order.fetch("order_status")
        success = (status == "paid")
        message = I18n.t(status, default: status, scope: "taler.order_status")

        ActiveMerchant::Billing::Response.new(success, message)
      end

      def void(response_code, gateway_options)
        payment = gateway_options[:payment]
        taler_order = taler_order(id: response_code)
        status = taler_order.fetch("order_status")

        if status == "claimed"
          return ActiveMerchant::Billing::Response.new(true, "Already expired")
        end

        raise "Unsupported action" if status != "paid"

        amount = taler_order.fetch("contract_terms")["amount"]
        taler_order.refund(refund: amount, reason: "void")

        PaymentMailer.refund_available(payment, taler_order.status_url).deliver_later

        ActiveMerchant::Billing::Response.new(true, "Refund initiated")
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
        fulfillment_url = urls.payment_gateways_confirm_taler_url(payment_id: payment.id)
        taler_order.create(
          amount: taler_amount,
          summary: I18n.t("payment_method_taler.order_summary"),
          fulfillment_url:,
        )
      end

      def taler_order(id: nil)
        @taler_order ||= ::Taler::Order.new(
          backend_url: preferred_backend_url,
          password: preferred_api_key,
          id:,
        )
      end
    end
  end
end
