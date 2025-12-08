# frozen_string_literal: true

# When directing a customer to Stripe to authorize the payment, we specify a
# redirect_url that Stripe should return them to. When checking out, it's
# /checkout; for admin payments and subscription payemnts it's the order url.
#
# This class confirms that the payment intent matches what's in our database,
# marks the payment as complete, and removes the redirect_auth_url field,
# which we use to indicate that authorization is required. It also completes the
# Order, if appropriate.

class ProcessPaymentIntent
  class Result
    attr_reader :error

    def initialize(success:, error: "")
      @success = success
      @error = error
    end

    def success?
      @success
    end
  end

  def initialize(payment_intent, order)
    @payment_intent = payment_intent
    @order = order
    @payment = order.payments.requires_authorization.with_payment_intent(payment_intent).first
  end

  def call!
    return Result.new(success: false) unless payment.present? && ready_for_capture?
    return Result.new(success: true) if already_processed?

    process_payment

    if payment.reload.completed?
      payment.complete_authorization
      payment.clear_authorization_url

      Result.new(success: true)
    else
      payment.fail_authorization
      payment.clear_authorization_url
      Result.new(success: false, error: I18n.t("payment_could_not_complete"))
    end
  rescue Stripe::StripeError => e
    payment.fail_authorization
    payment.clear_authorization_url
    Result.new(success: false, error: e.message)
  end

  private

  attr_reader :order, :payment_intent, :payment

  def process_payment
    return unless order.process_payments!

    Orders::WorkflowService.new(order).complete
  end

  def ready_for_capture?
    payment_intent_status == 'requires_capture'
  end

  def already_processed?
    payment_intent_status == 'succeeded'
  end

  def payment_intent_status
    @payment_intent_status ||= Stripe::PaymentIntentValidator.new(payment).call.status
  end
end
