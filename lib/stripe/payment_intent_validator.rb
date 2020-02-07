# frozen_string_literal: true

# This class validates if a given payment intent ID is valid in Stripe
module Stripe
  class PaymentIntentValidator
    def call(payment_intent_id, stripe_account_id)
      payment_intent_response = Stripe::PaymentIntent.retrieve(payment_intent_id,
                                                               stripe_account: stripe_account_id)
      if payment_intent_response.last_payment_error.present?
        raise Stripe::StripeError, payment_intent_response.last_payment_error.message
      end

      if payment_intent_response.status != 'requires_capture'
        raise Stripe::StripeError, I18n.t(:invalid_payment_state)
      end

      payment_intent_id
    end
  end
end
