# frozen_string_literal: true

# Use `authorize! :admin order` before calling this service

class OrderCaptureService
  attr_reader :gateway_error

  def initialize(order)
    @order = order
    @gateway_error = nil
  end

  def call
    return false unless @order.payment_required?
    return false unless (pending_payment = @order.pending_payments.first)

    pending_payment.capture!
  rescue Spree::Core::GatewayError => e
    @gateway_error = e
    false
  end
end
