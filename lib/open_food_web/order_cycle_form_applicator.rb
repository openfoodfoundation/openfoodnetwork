module OpenFoodWeb
  class OrderCycleFormApplicator
    def initialize(order_cycle)
      @order_cycle = order_cycle
    end

    def go!
      @order_cycle.incoming_exchanges.each do |exchange|
        if exchange_exists?(exchange[:enterprise_id], @order_cycle.coordinator_id)
          update_exchange(exchange[:enterprise_id], @order_cycle.coordinator_id)
        else
          add_exchange(exchange[:enterprise_id], @order_cycle.coordinator_id)
        end
      end
    end

    def exchange_exists?(sender_id, receiver_id)
      @order_cycle.exchanges.where(:sender_id => sender_id, :receiver_id => receiver_id).present?
    end

    def add_exchange(sender_id, receiver_id)
      @order_cycle.exchanges.create! :sender_id => sender_id, :receiver_id => receiver_id
    end

    def update_exchange(sender_id, receiver_id)
      # NOOP - when we're setting data on the exchange, we can do so here

      #exchange = @order_cycle.exchanges.where(:sender_id => sender_id, :receiver_id => receiver_id).first
    end

  end
end
