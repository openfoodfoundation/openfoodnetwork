# frozen_string_literal: true

module PaymentGateways
  # Shows the Nano payment instructions and takes the buyer's block hash.
  # See Spree::PaymentMethod::Nano.
  class NanoController < BaseController
    include OrderStockCheck
    include OrderCompletion

    class StockError < StandardError
    end

    before_action :load_nano_payment

    def show; end

    def confirm
      result = @payment_method.check_block(@payment, params[:block_hash])
      unless result.ok?
        flash.now[:error] = t(result.error, scope: "payment_method_nano.status")
        return render :show, status: :unprocessable_entity
      end

      @payment.update!(response_code: params[:block_hash].to_s.strip.upcase)

      unless @payment.process!
        return redirect_to order_failed_route(step: "payment")
      end

      OrderLocker.lock_order_and_variants(@order) do
        raise StockError unless sufficient_stock?

        process_payment_completion!
      end
    rescue Spree::Core::GatewayError => e
      flash[:notice] = e.message
      redirect_to order_failed_route(step: "payment")
    rescue StockError
      flash[:notice] = t("checkout.payment_cancelled_due_to_stock")
      redirect_to main_app.checkout_step_path(step: "details")
    end

    private

    # Only with the order's token, and only a Nano payment still in checkout.
    def load_nano_payment
      @payment = Spree::Payment.find(params[:payment_id])
      @order = @payment.order
      @payment_method = @payment.payment_method

      return if @payment_method.is_a?(Spree::PaymentMethod::Nano) &&
                @payment.checkout? && valid_order_token?

      redirect_to main_app.checkout_step_path(step: "payment")
    end

    def valid_order_token?
      @order.token.present? &&
        ActiveSupport::SecurityUtils.secure_compare(params[:order_token].to_s, @order.token)
    end
  end
end
