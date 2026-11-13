# frozen_string_literal: true

# Use `authorize! :admin order` before calling this service

module Orders
  class CaptureService
    attr_reader :gateway_error

    def initialize(order)
      @order = order
      @gateway_error = nil
    end

    def call
      return false unless @order.payment_required?
      return false if first_pending_payment.nil?

      first_pending_payment.capture!
    rescue Spree::Core::GatewayError => e
      @gateway_error = e
      false
    end

    private

    # We assume there is only one pending payment per order, that is not a customer credit payment
    def first_pending_payment
      return @first_pending_payment if defined? @first_pending_payment

      @first_pending_payment = @order.pending_payments.reject do |p|
        p.payment_method == Spree::PaymentMethod.customer_credit
      end.first
    end
  end
end
