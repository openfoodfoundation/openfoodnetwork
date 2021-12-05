# frozen_string_literal: true

class StripeController < BaseController
  include OrderStockCheck
  include OrderCompletion

  before_action :load_order, only: :confirm

  def confirm
    return processing_failed unless valid_payment_intent?

    process_payment_completion
  end

  private

  def load_order
    @order = current_order

    return order_invalid! if order_invalid_for_checkout?

    (cancel_incomplete_payments && handle_insufficient_stock) unless sufficient_stock?
  end

  def valid_payment_intent?
    @valid_payment_intent ||= begin
      return false unless params["payment_intent"]&.starts_with?("pi_")

      last_payment = OrderPaymentFinder.new(@order).last_payment

      @order.state == "payment" &&
        last_payment&.state == "requires_authorization" &&
        last_payment&.response_code == params["payment_intent"]
    end
  end

  def process_payment_completion
    return processing_failed unless @order.process_payments!

    if OrderWorkflow.new(@order).next && @order.complete?
      processing_succeeded
      redirect_to order_completion_route
    else
      processing_failed
      redirect_to order_failed_route
    end
  rescue Spree::Core::GatewayError => e
    gateway_error(e)
    processing_failed
  end

  def cancel_incomplete_payments
    # The checkout could not complete due to stock running out. We void any pending (incomplete)
    # Stripe payments here as the order will need to be changed and resubmitted (or abandoned).
    @order.payments.incomplete.each do |payment|
      payment.void_transaction!
      payment.adjustment&.update_columns(eligible: false, state: "finalized")
    end
    flash[:notice] = I18n.t("checkout.payment_cancelled_due_to_stock")
  end
end
