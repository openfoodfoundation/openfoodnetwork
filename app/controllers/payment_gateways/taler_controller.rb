# frozen_string_literal: true

module PaymentGateways
  class TalerController < BaseController
    include OrderCompletion

    # The Taler merchant backend has taken the payment.
    # Now we just need to confirm that and update our local database
    # before finalising the order.
    def confirm
      payment = Spree::Payment.find(params[:payment_id])
      @order = payment.order
      process_payment_completion!
    end
  end
end
