# frozen_string_literal: true

module PaymentGateways
  class StripeController < BaseController
    include OrderStockCheck
    include OrderCompletion

    before_action :load_checkout_order, only: :confirm
    before_action :validate_payment_intent, only: :confirm
    before_action :validate_stock, only: :confirm

    def confirm
      process_payment_completion!
    end

    private

    def validate_stock
      return if sufficient_stock?

      cancel_incomplete_payments
      handle_insufficient_stock
    end

    def validate_payment_intent
      return if valid_payment_intent?

      processing_failed
      redirect_to order_failed_route
    end

    def valid_payment_intent?
      @valid_payment_intent ||= begin
        return false unless params["payment_intent"]&.starts_with?("pi_")

        @order.state == "payment" &&
          last_payment&.state == "requires_authorization" &&
          last_payment&.response_code == params["payment_intent"]
      end
    end

    def last_payment
      @last_payment ||= OrderPaymentFinder.new(@order).last_payment
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
end
