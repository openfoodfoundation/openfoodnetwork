# frozen_string_literal: true

class ProcessPaymentIntent
  def initialize(payment_intent, order_number)
    @payment_intent = payment_intent
    @order = Spree::Order.find_by!(number: order_number)
    @last_payment = OrderPaymentFinder.new(@order).last_payment
  end

  def call!
    return unless valid?

    @last_payment.update_attribute(:cvv_response_message, nil)
    @last_payment.complete!
  end

  private

  def valid?
    @order.present? && valid_intent_string? && matches_last_payment?
  end

  def valid_intent_string?
    @payment_intent&.starts_with?("pi_")
  end

  def matches_last_payment?
    @last_payment&.state == "pending" && @last_payment&.response_code == @payment_intent
  end
end
