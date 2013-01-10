module OpenFoodWeb
  class OrderCycleFormApplicator
    def initialize(order_cycle)
      @order_cycle = order_cycle
    end

    def go!
      @touched_exchanges = []

      @order_cycle.incoming_exchanges.each do |exchange|
        variant_ids = exchange_variant_ids(exchange)

        if exchange_exists?(exchange[:enterprise_id], @order_cycle.coordinator_id)
          update_exchange(exchange[:enterprise_id], @order_cycle.coordinator_id, variant_ids)
        else
          add_exchange(exchange[:enterprise_id], @order_cycle.coordinator_id, variant_ids)
        end
      end

      destroy_untouched_exchanges
    end


    private

    attr_accessor :touched_exchanges

    def exchange_exists?(sender_id, receiver_id)
      @order_cycle.exchanges.where(:sender_id => sender_id, :receiver_id => receiver_id).present?
    end

    def add_exchange(sender_id, receiver_id, variant_ids)
      exchange = @order_cycle.exchanges.create! :sender_id => sender_id, :receiver_id => receiver_id, :variant_ids => variant_ids
      @touched_exchanges << exchange
    end

    def update_exchange(sender_id, receiver_id, variant_ids)
      exchange = @order_cycle.exchanges.where(:sender_id => sender_id, :receiver_id => receiver_id).first
      exchange.update_attributes!(:variant_ids => variant_ids)

      @touched_exchanges << exchange
    end

    def destroy_untouched_exchanges
      untouched_exchanges.each { |exchange| exchange.destroy }
    end

    def untouched_exchanges
      @order_cycle.exchanges - @touched_exchanges
    end


    def exchange_variant_ids(exchange)
      exchange[:variants].select { |k, v| v }.keys.map { |k| k.to_i }
    end
  end
end
