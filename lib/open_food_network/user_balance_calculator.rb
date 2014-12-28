module OpenFoodNetwork
  class UserBalanceCalculator
    def initialize(user, distributor)
      @user = user
      @distributor = distributor
    end
	
    def balance
      orders = Spree::Order.where(distributor_id: @distributor, user_id: @user)
      order_total = orders.sum &:total
	
      payments = Spree::Payment.where(order_id: orders)
      payment_total = payments.sum { |p| p.amount }
      payment_total-order_total
    end
  end
end
