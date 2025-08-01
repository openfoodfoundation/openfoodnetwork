# frozen_string_literal: true

module PaymentGateways
  class TwintController < BaseController
    include OrderStockCheck
    include OrderCompletion

    before_action :load_checkout_order, only: :confirm
    before_action :validate_payment_intent, only: :confirm
    before_action :check_order_cycle_expiry, only: :confirm

    def confirm
      validate_stock

      redirect_to order_failed_route if @any_out_of_stock == true
      @order.payments.last.state = "completed"
      @order.payments.last.captured_at = Time.zone.now
      @order.payments.last.update_columns(state: @order.payments.last.state,
                                          captured_at: @order.payments.last.captured_at)
      process_payment_completion!
    end

    private

    def validate_stock
      return if sufficient_stock?

      cancel_incomplete_payments
      handle_insufficient_stock
    end

    def validate_payment_intent
      return if params["redirect_status"] == "succeeded" && valid_payment_intent?

      processing_failed
      redirect_to order_failed_route
    end

    def valid_payment_intent?
      @valid_payment_intent ||= params["payment_intent"]&.starts_with?("pi_") &&
                                order_and_payment_valid?
    end

    def order_and_payment_valid?
      @order.state.in?(["payment", "confirmation"]) &&
        last_payment&.response_code == params["payment_intent"]
    end

    def last_payment
      @last_payment ||= Orders::FindPaymentService.new(@order).last_payment
    end

    def cancel_incomplete_payments
      # The checkout could not complete due to stock running out. We void any pending (incomplete)
      # Twint payments here as the order will need to be changed and resubmitted (or abandoned).
      @order.payments.incomplete.each do |payment|
        payment.void_transaction!
        payment.adjustment&.update_columns(eligible: false, state: "finalized")
      end
      flash[:notice] = I18n.t("checkout.payment_cancelled_due_to_stock")
    end
  end
end
