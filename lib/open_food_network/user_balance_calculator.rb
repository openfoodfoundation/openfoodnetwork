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
      completed_not_cancelled_orders.sum(&:total)
    end

    def payment_total
      payments.sum(&:amount)
    end

    def user_orders
      Spree::Order.where(distributor_id: @distributor, email: @email)
    end

    def completed_not_cancelled_orders
      user_orders.complete.not_state(:canceled)
    end

    # Lists all complete user payments including payments in incomplete or canceled orders
    def payments
      Spree::Payment.where(order_id: user_orders, state: "completed")
    end
  end
end
