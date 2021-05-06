# frozen_string_literal: true

# When directing a customer to Stripe to authorize the payment, we specify a
# redirect_url that Stripe should return them to. When checking out, it's
# /checkout; for admin payments and subscription payemnts it's the order url.
#
# This class confirms that the payment intent matches what's in our database,
# marks the payment as complete, and removes the cvv_response_message field,
# which we use to indicate that authorization is required. It also completes the
# Order, if appropriate.

class ProcessPaymentIntent
  class Result
    attr_reader :error

    def initialize(ok:, error: "")
      @ok = ok
      @error = error
    end

    def ok?
      @ok
    end
  end

  def initialize(payment_intent, order)
    @payment_intent = payment_intent
    @order = order
    @last_payment = OrderPaymentFinder.new(order).last_payment
  end

  def call!
    validate_intent!
    return Result.new(ok: false) unless valid?

    mark_as_processed

    OrderWorkflow.new(@order).next
    last_payment.complete! if last_payment.can_complete?

    Result.new(ok: true)
  rescue Stripe::StripeError => e
    Result.new(ok: false, error: e.message)
  end

  private

  attr_reader :order, :payment_intent, :last_payment

  def valid?
    order.present? && matches_last_payment?
  end

  def validate_intent!
    Stripe::PaymentIntentValidator.new.call(payment_intent, stripe_account_id)
  end

  def matches_last_payment?
    last_payment&.state == "pending" && last_payment&.response_code == payment_intent
  end

  def mark_as_processed
    last_payment.update_attribute(:cvv_response_message, nil)
  end

  def stripe_account_id
    StripeAccount.find_by(enterprise_id: preferred_enterprise_id).stripe_user_id
  end

  def preferred_enterprise_id
    last_payment.payment_method.preferred_enterprise_id
  end
end
