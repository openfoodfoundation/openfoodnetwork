# frozen_string_literal: true

module PaymentGateways
  class StripeController < BaseController
    include OrderStockCheck
    include OrderCompletion

    before_action :load_checkout_order, only: :confirm
    before_action :validate_payment_intent, only: :confirm
    before_action :check_order_cycle_expiry, only: :confirm
    before_action :validate_stock, only: :confirm

    def confirm
      process_payment_completion!
    end

    def authorize
      load_order_for_authorization

      return unless params.key?("payment_intent")

      result = ProcessPaymentIntent.new(params["payment_intent"], @order).call!

      unless result.ok?
        flash.now[:error] = "#{I18n.t('payment_could_not_process')}. #{result.error}"
      end

      redirect_to order_path(@order)
    end

    private

    def load_order_for_authorization
      require_order_authentication!

      session[:access_token] ||= params[:order_token]
      @order = Spree::Order.find_by(number: params[:order_number]) || current_order

      if @order
        authorize! :edit, @order, session[:access_token]
      else
        authorize! :create, Spree::Order
      end
    end

    def require_order_authentication!
      return if session[:access_token] || params[:order_token] || spree_current_user

      flash[:error] = I18n.t("spree.orders.edit.login_to_view_order")
      redirect_to root_path(anchor: "login", after_login: request.original_fullpath)
    end

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

        order_and_payment_valid?
      end
    end

    def order_and_payment_valid?
      @order.state.in?(["payment", "confirmation"]) &&
        last_payment&.state == "requires_authorization" &&
        last_payment&.response_code == params["payment_intent"]
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
