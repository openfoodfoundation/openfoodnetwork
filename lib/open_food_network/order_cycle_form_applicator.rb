module OpenFoodNetwork

  # There are two translator classes on the boundary between Angular and Rails: On the Angular side,
  # there is the OrderCycle#dataForSubmit method, and on the Rails side is this class. I think data
  # translation is more a responsibility of Angular, so I'd be inclined to refactor this class to move
  # as much as possible (if not all) of its logic into Angular.
  class OrderCycleFormApplicator
    def initialize(order_cycle)
      @order_cycle = order_cycle
    end

    def go!
      @touched_exchanges = []

      @order_cycle.incoming_exchanges ||= []
      @order_cycle.incoming_exchanges.each do |exchange|
        variant_ids = exchange_variant_ids(exchange)
        enterprise_fee_ids = exchange[:enterprise_fee_ids]

        if exchange_exists?(exchange[:enterprise_id], @order_cycle.coordinator_id)
          update_exchange(exchange[:enterprise_id], @order_cycle.coordinator_id,
                          {variant_ids: variant_ids, enterprise_fee_ids: enterprise_fee_ids})
        else
          add_exchange(exchange[:enterprise_id], @order_cycle.coordinator_id,
                       {variant_ids: variant_ids, enterprise_fee_ids: enterprise_fee_ids})
        end
      end

      @order_cycle.outgoing_exchanges ||= []
      @order_cycle.outgoing_exchanges.each do |exchange|
        variant_ids = exchange_variant_ids(exchange)
        enterprise_fee_ids = exchange[:enterprise_fee_ids]

        if exchange_exists?(@order_cycle.coordinator_id, exchange[:enterprise_id])
          update_exchange(@order_cycle.coordinator_id, exchange[:enterprise_id],
                          {variant_ids: variant_ids, enterprise_fee_ids: enterprise_fee_ids,
                           pickup_time: exchange[:pickup_time], pickup_instructions: exchange[:pickup_instructions]})
        else
          add_exchange(@order_cycle.coordinator_id, exchange[:enterprise_id],
                       {variant_ids: variant_ids, enterprise_fee_ids: enterprise_fee_ids,
                        pickup_time: exchange[:pickup_time], pickup_instructions: exchange[:pickup_instructions]})
        end
      end

      destroy_untouched_exchanges
    end


    private

    attr_accessor :touched_exchanges

    def exchange_exists?(sender_id, receiver_id)
      @order_cycle.exchanges.where(:sender_id => sender_id, :receiver_id => receiver_id).present?
    end

    def add_exchange(sender_id, receiver_id, attrs={})
      attrs = attrs.reverse_merge(:sender_id => sender_id, :receiver_id => receiver_id)
      exchange = @order_cycle.exchanges.create! attrs
      @touched_exchanges << exchange
    end

    def update_exchange(sender_id, receiver_id, attrs={})
      exchange = @order_cycle.exchanges.where(:sender_id => sender_id, :receiver_id => receiver_id).first
      exchange.update_attributes!(attrs)

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
