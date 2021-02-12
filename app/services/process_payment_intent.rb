# frozen_string_literal: true

class ProcessPaymentIntent
  def initialize(payment_intent, order)
    @payment_intent = payment_intent
    @order = order
    @last_payment = OrderPaymentFinder.new(order).last_payment
  end

  def call!
    return unless valid?

    last_payment.update_attribute(:cvv_response_message, nil)
    OrderWorkflow.new(@order).next
    last_payment.complete! if !last_payment.completed?
  end

  private

  attr_reader :order, :payment_intent, :last_payment

  def valid?
    order.present? && valid_intent_string? && matches_last_payment?
  end

  def valid_intent_string?
    payment_intent&.starts_with?("pi_")
  end

  def matches_last_payment?
    last_payment&.state == "pending" && last_payment&.response_code == payment_intent
  end
end
