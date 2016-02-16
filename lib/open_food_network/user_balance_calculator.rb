module OpenFoodNetwork
  class UserBalanceCalculator
    def initialize(email, distributor)
      @email = email
      @distributor = distributor
    end

    def balance
      payment_total - completed_order_total
    end


    private

    def completed_order_total
      orders.complete.sum &:total
    end

    def payment_total
      payments.sum &:amount
    end


    def orders
      Spree::Order.where(distributor_id: @distributor, email: @email)
    end

    def payments
      Spree::Payment.where(order_id: orders, state: "completed")
    end
  end
end
