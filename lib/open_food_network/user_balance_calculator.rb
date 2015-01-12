module OpenFoodNetwork
  class UserBalanceCalculator
    def initialize(user, distributor)
      @user = user
      @distributor = distributor
    end

    def balance
      payment_total - order_total
    end


    private

    def order_total
      orders.sum &:total
    end

    def payment_total
      payments.sum &:amount
    end


    def orders
      Spree::Order.where(distributor_id: @distributor, user_id: @user)
    end

    def payments
      Spree::Payment.where(order_id: orders)
    end
  end
end
