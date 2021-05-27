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
    @payment = order.payments.pending.with_payment_intent(payment_intent).first
  end

  def call!
    return Result.new(ok: false) unless payment.present? && ready_for_capture?
    return Result.new(ok: true) if already_processed?

    process_payment

    if payment.reload.completed?
      payment.completed_authorization
      payment.clear_authorization_url

      Result.new(ok: true)
    else
      payment.failed_authorization
      Result.new(ok: false, error: I18n.t("payment_could_not_complete"))
    end

  rescue Stripe::StripeError => e
    Result.new(ok: false, error: e.message)
  end

  private

  attr_reader :order, :payment_intent, :payment

  def process_payment
    if order.state == "payment"
      # Moves the order to completed, which calls #process_payments!
      OrderWorkflow.new(order).next
    else
      order.process_payments!
    end
  end

  def ready_for_capture?
    payment_intent_status == 'requires_capture'
  end

  def already_processed?
    payment_intent_status == 'succeeded'
  end

  def payment_intent_status
    @payment_intent_status ||= Stripe::PaymentIntentValidator.new.
      call(payment_intent, stripe_account_id).
      status
  end

  def stripe_account_id
    StripeAccount.find_by(enterprise_id: preferred_enterprise_id).stripe_user_id
  end

  def preferred_enterprise_id
    payment.payment_method.preferred_enterprise_id
  end
end
