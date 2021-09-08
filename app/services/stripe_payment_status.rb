# frozen_string_literal: true

class StripePaymentStatus
  def initialize(payment)
    @payment = payment
  end

  # Returns the current payment status from a live call to the Stripe API.
  # Returns nil if the payment is not a Stripe payment or does not have a payment intent.
  # If the payment requires authorization the status will be "requires_action".
  # If the payment has been captured the status will be "succeeded".
  # Docs: https://stripe.com/docs/api/payment_intents/object#payment_intent_object-status
  def stripe_status
    return if payment.response_code.blank?

    Stripe::PaymentIntentValidator.new(payment).call.status
  rescue Stripe::StripeError
    # Stripe::PaymentIntentValidator will raise an error if the response from the Stripe API
    # call indicates the last attempted action on the payment intent failed.
    "failed"
  end

  # If the payment is a Stripe payment and has been captured in the associated Stripe account,
  # returns true, otherwise false.
  def stripe_captured?
    stripe_status == "succeeded"
  end

  private

  attr_reader :payment
end
