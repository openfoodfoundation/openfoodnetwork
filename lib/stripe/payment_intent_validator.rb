# frozen_string_literal: true

# This class validates if a given payment intent ID is valid in Stripe
module Stripe
  class PaymentIntentValidator
    def call(payment)
      payment_intent_response = Stripe::PaymentIntent.retrieve(
        payment_intent_id(payment),
        stripe_account: stripe_account_id(payment)
      )

      raise_if_last_payment_error_present(payment_intent_response)

      payment_intent_response
    end

    private

    def payment_intent_id(payment)
      payment.response_code
    end

    def stripe_account_id(payment)
      enterprise_id = payment.payment_method&.preferred_enterprise_id

      StripeAccount.find_by(enterprise_id: enterprise_id)&.stripe_user_id
    end

    def raise_if_last_payment_error_present(payment_intent_response)
      return unless payment_intent_response.respond_to?(:last_payment_error) &&
                    payment_intent_response.last_payment_error.present?

      raise Stripe::StripeError, payment_intent_response.last_payment_error.message
    end
  end
end
