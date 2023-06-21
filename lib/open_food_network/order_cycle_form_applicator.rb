# frozen_string_literal: true

require 'open_food_network/order_cycle_permissions'

module OpenFoodNetwork
  # There are two translator classes on the boundary between Angular and Rails: On the Angular side,
  # there is the OrderCycle#dataForSubmit method, and on the Rails side is this class. I think data
  # translation is more a responsibility of Angular, so I'd be inclined to refactor this class to
  # move as much as possible (if not all) of its logic into Angular.
  class OrderCycleFormApplicator
    # The applicator will only touch exchanges where a permitted enterprise is the participant
    def initialize(order_cycle, spree_current_user)
      @order_cycle = order_cycle
      @spree_current_user = spree_current_user
    end

    def go!
      @touched_exchanges = []

      @order_cycle.incoming_exchanges ||= []
      @order_cycle.incoming_exchanges.each do |exchange|
        variant_ids = incoming_exchange_variant_ids(exchange)
        enterprise_fee_ids = exchange[:enterprise_fee_ids]

        if exchange_exists?(exchange[:enterprise_id], @order_cycle.coordinator_id, true)
          update_exchange(exchange[:enterprise_id], @order_cycle.coordinator_id, true,
                          variant_ids: variant_ids, enterprise_fee_ids: enterprise_fee_ids,
                          receival_instructions: exchange[:receival_instructions] )
        else
          add_exchange(exchange[:enterprise_id], @order_cycle.coordinator_id, true,
                       variant_ids: variant_ids, enterprise_fee_ids: enterprise_fee_ids,
                       receival_instructions: exchange[:receival_instructions], )
        end
      end

      @order_cycle.outgoing_exchanges ||= []
      @order_cycle.outgoing_exchanges.each do |exchange|
        variant_ids = outgoing_exchange_variant_ids(exchange)
        enterprise_fee_ids = exchange[:enterprise_fee_ids]

        if exchange_exists?(@order_cycle.coordinator_id, exchange[:enterprise_id], false)
          update_exchange(@order_cycle.coordinator_id, exchange[:enterprise_id], false,
                          variant_ids: variant_ids,
                          enterprise_fee_ids: enterprise_fee_ids,
                          pickup_time: exchange[:pickup_time],
                          pickup_instructions: exchange[:pickup_instructions],
                          tag_list: exchange[:tag_list] )
        else
          add_exchange(@order_cycle.coordinator_id, exchange[:enterprise_id], false,
                       variant_ids: variant_ids,
                       enterprise_fee_ids: enterprise_fee_ids,
                       pickup_time: exchange[:pickup_time],
                       pickup_instructions: exchange[:pickup_instructions],
                       tag_list: exchange[:tag_list] )
        end
      end

      destroy_untouched_exchanges
    end

    private

    attr_accessor :touched_exchanges

    def exchange_exists?(sender_id, receiver_id, incoming)
      @order_cycle.exchanges.where(sender_id: sender_id, receiver_id: receiver_id,
                                   incoming: incoming).present?
    end

    def add_exchange(sender_id, receiver_id, incoming, attrs = {})
      attrs = attrs.reverse_merge(sender_id: sender_id, receiver_id: receiver_id,
                                  incoming: incoming)
      variant_ids = attrs.delete :variant_ids
      exchange = @order_cycle.exchanges.build attrs

      if manages_coordinator?
        exchange.save!
        ExchangeVariantBulkUpdater.new(exchange).update!(variant_ids) unless variant_ids.nil?

        @touched_exchanges << exchange
      end
    end

    def update_exchange(sender_id, receiver_id, incoming, attrs = {})
      exchange = @order_cycle.exchanges.where(sender_id: sender_id, receiver_id: receiver_id,
                                              incoming: incoming).first
      return unless permission_for(exchange)

      remove_unauthorized_exchange_attributes(exchange, attrs)
      variant_ids = attrs.delete :variant_ids
      exchange.update!(attrs)
      ExchangeVariantBulkUpdater.new(exchange).update!(variant_ids) unless variant_ids.nil?

      @touched_exchanges << exchange
    end

    def remove_unauthorized_exchange_attributes(exchange, exchange_attrs)
      return if manages_coordinator? || manager_for(exchange)

      exchange_attrs.delete :enterprise_fee_ids
      exchange_attrs.delete :pickup_time
      exchange_attrs.delete :pickup_instructions
      exchange_attrs.delete :tag_list
    end

    def destroy_untouched_exchanges
      if manages_coordinator?
        untouched_exchanges.each(&:destroy)
      end
    end

    def untouched_exchanges
      touched_exchange_ids = @touched_exchanges.map(&:id)
      @order_cycle.exchanges.reject { |ex| touched_exchange_ids.include? ex.id }
    end

    def manager_for(exchange)
      Enterprise.managed_by(@spree_current_user).include? exchange.participant
    end

    def permission_for(exchange)
      permitted_enterprises.include? exchange.participant
    end

    def permitted_enterprises
      return @permitted_enterprises unless @permitted_enterprises.nil?

      @permitted_enterprises = OpenFoodNetwork::OrderCyclePermissions.
        new(@spree_current_user, @order_cycle).visible_enterprises
    end

    def manages_coordinator?
      return @manages_coordinator unless @manages_coordinator.nil?

      @manages_coordinator =
        Enterprise.managed_by(@spree_current_user).include? @order_cycle.coordinator
    end

    def editable_variant_ids_for_incoming_exchange_between(sender, _receiver)
      OpenFoodNetwork::OrderCyclePermissions.new(@spree_current_user, @order_cycle).
        editable_variants_for_incoming_exchanges_from(sender).pluck(:id)
    end

    def editable_variant_ids_for_outgoing_exchange_between(_sender, receiver)
      OpenFoodNetwork::OrderCyclePermissions.new(@spree_current_user, @order_cycle).
        editable_variants_for_outgoing_exchanges_to(receiver).pluck(:id)
    end

    def find_exchange(sender_id, receiver_id, incoming)
      @order_cycle.exchanges.
        find_by(sender_id: sender_id, receiver_id: receiver_id, incoming: incoming)
    end

    def incoming_exchange_variant_ids(attrs)
      sender = Enterprise.find(attrs[:enterprise_id])
      receiver = @order_cycle.coordinator
      exchange = find_exchange(sender.id, receiver.id, true)

      requested_ids = variants_to_a(attrs[:variants]) # Only the ids the user has requested
      # The ids that already exist
      existing_ids = exchange.present? ? exchange.variants.pluck(:id) : []
      # The ids we are allowed to add/remove
      editable_ids = editable_variant_ids_for_incoming_exchange_between(sender, receiver)

      result = existing_ids

      # add any requested & editable ids that are not yet in the exchange
      result |= (requested_ids & editable_ids)
      # remove any editable ids that were not specifically mentioned in the request
      result -= ((result & editable_ids) - requested_ids)

      result
    end

    def outgoing_exchange_variant_ids(attrs)
      sender = @order_cycle.coordinator
      receiver = Enterprise.find(attrs[:enterprise_id])
      exchange = find_exchange(sender.id, receiver.id, false)

      requested_ids = variants_to_a(attrs[:variants]) # Only the ids the user has requested
      # The ids that already exist
      existing_ids = exchange.present? ? exchange.variants.pluck(:id) : []
      # The ids we are allowed to add/remove
      editable_ids = editable_variant_ids_for_outgoing_exchange_between(sender, receiver)

      result = existing_ids

      # add any requested & editable ids that are not yet in the exchange
      result |= (requested_ids & editable_ids)
      result -= (result - incoming_variant_ids) # remove any ids not in incoming exchanges
      # remove any editable ids that were not specifically mentioned in the request
      result -= ((result & editable_ids) - requested_ids)

      result
    end

    def incoming_variant_ids
      @order_cycle.supplied_variants.map(&:id)
    end

    def variants_to_a(variants)
      return [] unless variants

      variants.select { |_k, v| v }.keys.map(&:to_i)
    end
  end
end
