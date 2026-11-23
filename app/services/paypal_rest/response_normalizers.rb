# frozen_string_literal: true

module PaypalRest
  module ResponseNormalizers
    private

    def normalize_order_amount(response)
      return failure_from(response) unless response&.success?

      purchase_unit = response.data&.purchase_units&.first
      amount = purchase_unit&.amount
      return failure("PayPal did not return an order amount") if amount.nil?

      Result.new(
        success: true,
        amount: amount.value,
        currency_code: amount.currency_code
      )
    end

    def normalize_order(response)
      return failure_from(response) unless response&.success?

      order = response.data
      return failure("PayPal did not return an order ID") if order&.id.blank?

      approval_link = Array(order.links).find do |link|
        %w[approve payer-action].include?(link.rel)
      end

      Result.new(
        success: true,
        order_id: order.id,
        approval_url: approval_link&.href,
        status: order.status
      )
    end

    def normalize_capture(response)
      return failure_from(response) unless response&.success?

      order = response.data
      capture = capture_from(order)

      unless capture&.status == PaypalServerSdk::CaptureStatus::COMPLETED
        return failure("PayPal capture status: #{capture&.status || 'unknown'}")
      end

      return failure("PayPal did not return a capture ID") if capture.id.blank?

      capture_result(order, capture)
    end

    def capture_from(order)
      purchase_unit = order.purchase_units&.first
      Array(purchase_unit&.payments&.captures).first
    end

    def capture_result(order, capture)
      Result.new(
        success: true,
        order_id: order.id,
        capture_id: capture.id,
        payer_id: order.payer&.payer_id,
        status: capture.status
      )
    end

    def normalize_refund(response)
      return failure_from(response) unless response&.success?

      refund = response.data

      unless refund&.status == PaypalServerSdk::RefundStatus::COMPLETED
        return failure("PayPal refund status: #{refund&.status || 'unknown'}")
      end

      return failure("PayPal did not return a refund ID") if refund.id.blank?

      Result.new(
        success: true,
        refund_id: refund.id,
        status: refund.status
      )
    end

    def failure_from(response)
      message =
        if response.respond_to?(:errors) && response.errors.present?
          Array(response.errors).map { |error| error_description(error) }.join(" ")
        elsif response&.data.respond_to?(:message)
          response.data.message
        end

      failure(message)
    end

    def error_description(error)
      return error.description if error.respond_to?(:description) && error.description.present?

      error.to_s
    end

    def exception_message(error)
      response = error.respond_to?(:response) ? error.response : nil
      parsed_error_details(response&.raw_body) ||
        response&.reason_phrase.presence ||
        error.message
    end

    def parsed_error_details(raw_body)
      return nil if raw_body.blank?

      first_error = JSON.parse(raw_body)['errors']&.first
      first_error&.dig('description').presence || first_error&.dig('message').presence
    rescue JSON::ParserError
      nil
    end

    def failure(message)
      Result.new(success: false, error_message: message.presence || "PayPal request failed")
    end
  end
end
