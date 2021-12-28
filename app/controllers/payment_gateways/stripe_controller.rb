# frozen_string_literal: true

module PaymentGateways
  class StripeController < BaseController
    include OrderStockCheck
    include OrderCompletion

    before_action :load_checkout_order, only: :confirm

    def confirm
      return processing_failed unless valid_payment_intent?

      cancel_incomplete_payments && handle_insufficient_stock unless sufficient_stock?

      process_payment_completion!
    end

    private

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
