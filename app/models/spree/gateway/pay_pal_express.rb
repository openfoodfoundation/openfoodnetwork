# frozen_string_literal: true

require 'paypal-sdk-merchant'

module Spree
  class Gateway
    class PayPalExpress < Gateway
      preference :login, :string
      preference :password, :password
      preference :signature, :string
      preference :server, :string, default: 'sandbox'
      preference :solution, :string, default: 'Mark'
      preference :landing_page, :string, default: 'Billing'
      preference :logourl, :string, default: ''

      def external_gateway?
        true
      end

      def external_payment_url(_options)
        Rails.application.routes.url_helpers.
          payment_gateways_paypal_express_path(payment_method_id: id)
      end

      def supports?(_source)
        true
      end

      def provider_class
        ::PayPal::SDK::Merchant::API
      end

      def provider
        ::PayPal::SDK.configure(
          mode: preferred_server.presence || "sandbox",
          username: preferred_login,
          password: preferred_password,
          signature: preferred_signature
        )
        provider_class.new
      end

      def method_type
        'paypal'
      end

      def purchase(_amount, express_checkout, _gateway_options = {})
        pp_details_request = provider.build_get_express_checkout_details(
          Token: express_checkout.token
        )
        pp_details_response = provider.get_express_checkout_details(pp_details_request)

        pp_request = provider.build_do_express_checkout_payment(
          DoExpressCheckoutPaymentRequestDetails: {
            PaymentAction: "Sale",
            Token: express_checkout.token,
            PayerID: express_checkout.payer_id,
            PaymentDetails: pp_details_response.
              get_express_checkout_details_response_details.PaymentDetails
          }
        )

        pp_response = provider.do_express_checkout_payment(pp_request)
        if pp_response.success?
          # We need to store the transaction id for the future.
          # This is mainly so we can use it later on to refund the payment if the user wishes.
          transaction_id = pp_response.do_express_checkout_payment_response_details.
            payment_info.first.transaction_id
          express_checkout.update_column(:transaction_id, transaction_id)
          # This is rather hackish, required for payment/processing handle_response code.
          Class.new do
            def success?; true; end

            def authorization; nil; end
          end.new
        else
          class << pp_response
            def to_s
              errors.map(&:long_message).join(" ")
            end
          end
          pp_response
        end
      end

      def refund(payment, amount)
        refund_type = payment.amount == amount.to_f ? "Full" : "Partial"
        refund_transaction = provider.build_refund_transaction(
          TransactionID: payment.source.transaction_id,
          RefundType: refund_type,
          Amount: {
            currencyID: payment.currency,
            value: amount
          },
          RefundSource: "any"
        )
        refund_transaction_response = provider.refund_transaction(refund_transaction)
        if refund_transaction_response.success?
          payment.source.update(
            refunded_at: Time.now,
            refund_transaction_id: refund_transaction_response.RefundTransactionID,
            state: "refunded",
            refund_type: refund_type
          )

          payment.class.create!(
            order: payment.order,
            source: payment,
            payment_method: payment.payment_method,
            amount: amount.to_f.abs * -1,
            response_code: refund_transaction_response.RefundTransactionID,
            state: 'completed'
          )
        end
        refund_transaction_response
      end
    end
  end
end
