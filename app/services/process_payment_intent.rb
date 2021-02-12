# frozen_string_literal: true

# When directing a customer to Stripe to authorize the payment, we specify a
# redirect_url that Stripe should return them to. When checking out, it's
# /checkout; for admin payments and subscription payemnts it's the order url.
# This class confirms that the payment intent matches what's in our database,
# marks the payment as complete, and removes the cvv_response_message field,
# which we use to indicate that authorization is required. It also completes the
# Order, if appropriate.

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
