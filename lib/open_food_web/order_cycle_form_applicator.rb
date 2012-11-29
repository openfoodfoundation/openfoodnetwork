module OpenFoodWeb
  class OrderCycleFormApplicator
    def initialize(order_cycle)
      @order_cycle = order_cycle
    end

    def go!
      @order_cycle.incoming_exchanges.each do |exchange|
        add_exchange(exchange[:enterprise_id], @order_cycle.coordinator_id)
      end
    end

    def add_exchange(sender_id, receiver_id)
      @order_cycle.exchanges.create! :sender_id => sender_id, :receiver_id => receiver_id
    end

  end
end
