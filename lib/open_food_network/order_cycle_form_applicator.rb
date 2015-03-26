module OpenFoodNetwork

  # There are two translator classes on the boundary between Angular and Rails: On the Angular side,
  # there is the OrderCycle#dataForSubmit method, and on the Rails side is this class. I think data
  # translation is more a responsibility of Angular, so I'd be inclined to refactor this class to move
  # as much as possible (if not all) of its logic into Angular.
  class OrderCycleFormApplicator
    # The applicator will only touch exchanges where a permitted enterprise is the participant
    def initialize(order_cycle, spree_current_user, permitted_enterprises)
      @order_cycle = order_cycle
      @spree_current_user = spree_current_user
      @permitted_enterprises = permitted_enterprises
    end

    def go!
      @touched_exchanges = []

      @order_cycle.incoming_exchanges ||= []
      @order_cycle.incoming_exchanges.each do |exchange|
        variant_ids = incoming_exchange_variant_ids(exchange)
        enterprise_fee_ids = exchange[:enterprise_fee_ids]

        if exchange_exists?(exchange[:enterprise_id], @order_cycle.coordinator_id, true)
          update_exchange(exchange[:enterprise_id], @order_cycle.coordinator_id, true,
                          {variant_ids: variant_ids, enterprise_fee_ids: enterprise_fee_ids})
        else
          add_exchange(exchange[:enterprise_id], @order_cycle.coordinator_id, true,
                       {variant_ids: variant_ids, enterprise_fee_ids: enterprise_fee_ids})
        end
      end

      @order_cycle.outgoing_exchanges ||= []
      @order_cycle.outgoing_exchanges.each do |exchange|
        variant_ids = outgoing_exchange_variant_ids(exchange)
        enterprise_fee_ids = exchange[:enterprise_fee_ids]

        if exchange_exists?(@order_cycle.coordinator_id, exchange[:enterprise_id], false)
          update_exchange(@order_cycle.coordinator_id, exchange[:enterprise_id], false,
                          {variant_ids: variant_ids, enterprise_fee_ids: enterprise_fee_ids,
                           pickup_time: exchange[:pickup_time], pickup_instructions: exchange[:pickup_instructions]})
        else
          add_exchange(@order_cycle.coordinator_id, exchange[:enterprise_id], false,
                       {variant_ids: variant_ids, enterprise_fee_ids: enterprise_fee_ids,
                        pickup_time: exchange[:pickup_time], pickup_instructions: exchange[:pickup_instructions]})
        end
      end

      destroy_untouched_exchanges
    end


    private

    attr_accessor :touched_exchanges

    def exchange_exists?(sender_id, receiver_id, incoming)
      @order_cycle.exchanges.where(:sender_id => sender_id, :receiver_id => receiver_id, :incoming => incoming).present?
    end

    def add_exchange(sender_id, receiver_id, incoming, attrs={})
      attrs = attrs.reverse_merge(:sender_id => sender_id, :receiver_id => receiver_id, :incoming => incoming)
      exchange = @order_cycle.exchanges.build attrs

      if permission_for exchange
        exchange.save!
        @touched_exchanges << exchange
      end
    end

    def update_exchange(sender_id, receiver_id, incoming, attrs={})
      exchange = @order_cycle.exchanges.where(:sender_id => sender_id, :receiver_id => receiver_id, :incoming => incoming).first

      if permission_for exchange
        exchange.update_attributes!(attrs)
        @touched_exchanges << exchange
      end
    end

    def destroy_untouched_exchanges
      with_permission(untouched_exchanges).each(&:destroy)
    end

    def untouched_exchanges
      touched_exchange_ids = @touched_exchanges.map(&:id)
      @order_cycle.exchanges.reject { |ex| touched_exchange_ids.include? ex.id }
    end

    def with_permission(exchanges)
      exchanges.select { |ex| permission_for(ex) }
    end

    def permission_for(exchange)
      @permitted_enterprises.include? exchange.participant
    end

    # TODO Need to use editable rather than visible
    def editable_variant_ids_for_incoming_exchange_between(sender, receiver)
      OpenFoodNetwork::Permissions.new(@spree_current_user).
        visible_variants_for_incoming_exchanges_between(sender, receiver).
        pluck(:id)
    end

    # TODO Need to use editable rather than visible
    def editable_variant_ids_for_outgoing_exchange_between(sender, receiver)
      OpenFoodNetwork::Permissions.new(@spree_current_user).
      visible_variants_for_outgoing_exchanges_between(sender, receiver, order_cycle: @order_cycle).
      pluck(:id)
    end

    def find_incoming_exchange(attrs)
      @order_cycle.exchanges.
      where(:sender_id => attrs[:enterprise_id], :receiver_id => @order_cycle.coordinator_id, :incoming => true).first
    end

    def find_outgoing_exchange(attrs)
      @order_cycle.exchanges.
      where(:sender_id => @order_cycle.coordinator_id, :receiver_id => attrs[:enterprise_id], :incoming => false).first
    end

    def persisted_variants_hash(exchange)
      exchange ||= OpenStruct.new(variants: [])
      Hash[ exchange.variants.map{ |v| [v.id, true] } ]
    end

    def incoming_exchange_variant_ids(attrs)
      exchange = find_incoming_exchange(attrs)
      variants = persisted_variants_hash(exchange)

      sender = exchange.andand.sender || Enterprise.find(attrs[:enterprise_id])
      receiver = @order_cycle.coordinator
      permitted = editable_variant_ids_for_incoming_exchange_between(sender, receiver)

      # Only change visibility for variants I have permission to edit
      attrs[:variants].each do |variant_id, value|
        variants[variant_id.to_i] = value  if permitted.include?(variant_id.to_i)
      end

      variants.select { |k, v| v }.keys.map { |k| k.to_i }.sort
    end

    def outgoing_exchange_variant_ids(attrs)
      exchange = find_outgoing_exchange(attrs)
      variants = persisted_variants_hash(exchange)

      sender = @order_cycle.coordinator
      receiver = exchange.andand.receiver || Enterprise.find(attrs[:enterprise_id])
      permitted = editable_variant_ids_for_outgoing_exchange_between(sender, receiver)

      # Only change visibility for variants I have permission to edit
      attrs[:variants].each do |variant_id, value|
        variants[variant_id.to_i] = value  if permitted.include?(variant_id.to_i)
      end

      variants.select { |k, v| v }.keys.map { |k| k.to_i }.sort
    end
  end
end
