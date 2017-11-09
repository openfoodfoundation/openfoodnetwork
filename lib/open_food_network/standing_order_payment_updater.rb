module OpenFoodNetwork
  class StandingOrderPaymentUpdater

    def initialize(order)
      @order = order
    end

    def update!
      return unless payment
      payment.update_attributes(amount: @order.outstanding_balance)
    end

    private

    def payment
      @payment ||= @order.pending_payments.last
    end
  end
end
