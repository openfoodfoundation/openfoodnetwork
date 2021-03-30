module OpenFoodNetwork
  class UserBalanceCalculator
    def initialize(email, distributor)
      @email = email
      @distributor = distributor
    end

    def balance
      -completed_orders.to_a.sum(&:old_outstanding_balance)
    end

    private

    def completed_orders
      Spree::Order.where(distributor_id: @distributor, email: @email).complete.not_state(:canceled)
    end
  end
end
