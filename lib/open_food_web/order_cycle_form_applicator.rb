module OpenFoodWeb
  class OrderCycleFormApplicator
    def initialize(order_cycle)
      @order_cycle = order_cycle
    end

    def go!
      @touched_exchanges = []

      @order_cycle.incoming_exchanges.each do |exchange|
        if exchange_exists?(exchange[:enterprise_id], @order_cycle.coordinator_id)
          update_exchange(exchange[:enterprise_id], @order_cycle.coordinator_id)
        else
          add_exchange(exchange[:enterprise_id], @order_cycle.coordinator_id)
        end
      end

      destroy_untouched_exchanges
    end

    def exchange_exists?(sender_id, receiver_id)
      @order_cycle.exchanges.where(:sender_id => sender_id, :receiver_id => receiver_id).present?
    end

    def add_exchange(sender_id, receiver_id)
      exchange = @order_cycle.exchanges.create! :sender_id => sender_id, :receiver_id => receiver_id
      @touched_exchanges << exchange
    end

    def update_exchange(sender_id, receiver_id)
      # NOOP - when we're setting data on the exchange, we can do so here

      exchange = @order_cycle.exchanges.where(:sender_id => sender_id, :receiver_id => receiver_id).first
      @touched_exchanges << exchange
    end

    def destroy_untouched_exchanges
      untouched_exchanges.each { |exchange| exchange.destroy }
    end

    def untouched_exchanges
      @order_cycle.exchanges - @touched_exchanges
    end

  end
end
