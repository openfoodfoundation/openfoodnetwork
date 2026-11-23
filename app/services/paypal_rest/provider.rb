# frozen_string_literal: true

module PaypalRest
  class Provider
    def initialize(options = {})
      @client = Client.new(
        client_id: options[:client_id],
        client_secret: options[:client_secret],
        environment: options[:server]
      )
    end

    def create_order(order_request, request_id: nil)
      @client.create_order(order_request, request_id:)
    end

    def purchase(amount, source, _options = {})
      return failed_response("Missing PayPal order ID") if source&.order_id.blank?

      error = amount_mismatch(source.order_id, amount)
      return failed_response(error) if error

      result = @client.capture_order(
        source.order_id, {}, request_id: "ofn-capture-#{source.order_id}"
      )

      if result.success? && result.capture_id.present?
        source.update!(
          capture_id: result.capture_id,
          payer_id: result.payer_id,
          status: result.status
        )
        ActiveMerchant::Billing::Response.new(
          true, "PayPal capture #{result.status}", {}, authorization: result.capture_id
        )
      else
        failed_response(
          result.error_message.presence || "PayPal did not return a capture ID"
        )
      end
    end

    def refund(money, capture_id, options = {})
      return failed_response("Missing PayPal capture ID") if capture_id.blank?

      payment = options[:payment]
      return failed_response("Missing payment for PayPal refund") if payment.nil?
      return failed_response("Missing payment source for PayPal refund") if payment.source.nil?

      amount = money / 100.0
      result = @client.refund_capture(
        capture_id,
        refund_request(amount, options[:currency]),
        request_id: refund_request_id(capture_id, amount)
      )

      return failed_response(result.error_message) unless result.success?

      payment.source.update!(
        refund_id: result.refund_id,
        refunded_at: Time.zone.now,
        status: "refunded"
      )
      ActiveMerchant::Billing::Response.new(
        true, "PayPal refund #{result.status}", {}, authorization: result.refund_id
      )
    end

    def authorize(*)
      unsupported_operation(:authorize)
    end

    def capture(*)
      unsupported_operation(:capture)
    end

    def credit(*)
      unsupported_operation(:credit)
    end

    def void(*)
      unsupported_operation(:void)
    end

    private

    def amount_mismatch(order_id, amount)
      order = @client.order_amount(order_id)
      return order.error_message unless order.success?

      expected = BigDecimal(amount.to_s) / 100
      return nil if BigDecimal(order.amount.to_s) == expected

      "PayPal order amount #{order.amount} #{order.currency_code} " \
        "does not match payment amount #{format('%.2f', expected)}"
    end

    def refund_request(amount, currency)
      PaypalServerSdk::RefundRequest.new(
        amount: PaypalServerSdk::Money.new(
          value: format("%.2f", amount), currency_code: currency
        )
      )
    end

    def refund_request_id(capture_id, amount)
      "ofn-refund-#{capture_id}-#{format('%.2f', amount)}"
    end

    def failed_response(message)
      ActiveMerchant::Billing::Response.new(false, message)
    end

    def unsupported_operation(name)
      failed_response("#{name} is not supported for immediate-capture PayPal payments")
    end
  end
end
