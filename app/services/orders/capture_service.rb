# frozen_string_literal: true

# Use `authorize! :admin order` before calling this service

module Orders
  class CaptureService
    attr_reader :gateway_error, :error

    def initialize(order)
      @order = order
      @gateway_error = nil
      @error = nil
    end

    def call
      unless @order.payment_required?
        @error = :nothing_to_capture
        return false
      end

      payment = @order.capturable_pending_payments.max_by(&:created_at)
      if payment.nil?
        @error = :nothing_to_capture
        return false
      end

      payment.capture!
    rescue Spree::Core::GatewayError => e
      @gateway_error = e
      false
    end
  end
end
