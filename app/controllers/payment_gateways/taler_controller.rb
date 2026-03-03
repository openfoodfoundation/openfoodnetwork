# frozen_string_literal: true

module PaymentGateways
  class TalerController < BaseController
    include OrderStockCheck
    include OrderCompletion

    class StockError < StandardError
    end

    # The Taler merchant backend has taken the payment.
    # Now we just need to confirm that and update our local database
    # before finalising the order.
    def confirm
      payment = Spree::Payment.find(params[:payment_id])

      # Process payment early because it's probably paid already.
      # We want to capture that before any validations raise errors.
      unless payment.process!
        return redirect_to order_failed_route(step: "payment")
      end

      @order = payment.order
      OrderLocker.lock_order_and_variants(@order) do
        raise StockError unless sufficient_stock?

        process_payment_completion!
      end
    rescue StockError
      flash[:notice] = t("checkout.payment_cancelled_due_to_stock")
      redirect_to main_app.checkout_step_path(step: "details")
    end
  end
end
