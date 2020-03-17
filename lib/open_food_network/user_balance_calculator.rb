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
      completed_orders.sum(&:total)
    end

    def payment_total
      payments.sum(&:amount)
    end

    def completed_orders
      all_orders.complete.not_state(:canceled)
    end

    def all_orders
      Spree::Order.where(distributor_id: @distributor, email: @email)
    end

    def payments
      Spree::Payment.where(order_id: all_orders, state: "completed")
    end
  end
end
