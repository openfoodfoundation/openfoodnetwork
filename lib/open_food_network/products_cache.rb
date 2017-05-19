require 'open_food_network/products_cache_refreshment'

# When elements of the data model change, refresh the appropriate parts of the products cache.

module OpenFoodNetwork
  class ProductsCache
    def self.variant_changed(variant)
      exchanges_featuring_variants(variant).each do |exchange|
        refresh_cache exchange.receiver, exchange.order_cycle
      end
    end

    def self.variant_destroyed(variant, &block)
      exchanges = exchanges_featuring_variants(variant).to_a

      block.call

      exchanges.each do |exchange|
        refresh_cache exchange.receiver, exchange.order_cycle
      end
    end

    def self.product_changed(product)
      exchanges_featuring_variants(product.variants).each do |exchange|
        refresh_cache exchange.receiver, exchange.order_cycle
      end
    end

    def self.product_deleted(product, &block)
      exchanges = exchanges_featuring_variants(product.reload.variants).to_a

      block.call

      exchanges.each do |exchange|
        refresh_cache exchange.receiver, exchange.order_cycle
      end
    end

    def self.variant_override_changed(variant_override)
      exchanges_featuring_variants(variant_override.variant, distributor: variant_override.hub).each do |exchange|
        refresh_cache exchange.receiver, exchange.order_cycle
      end
    end

    def self.variant_override_destroyed(variant_override)
      variant_override_changed variant_override
    end

    def self.producer_property_changed(producer_property)
      products = producer_property.producer.supplied_products
      variants = Spree::Variant.
                 where(is_master: false, deleted_at: nil).
                 where(product_id: products)

      exchanges_featuring_variants(variants).each do |exchange|
        refresh_cache exchange.receiver, exchange.order_cycle
      end
    end

    def self.producer_property_destroyed(producer_property)
      producer_property_changed producer_property
    end

    def self.order_cycle_changed(order_cycle)
      if order_cycle.dated? && !order_cycle.closed?
        order_cycle.exchanges.outgoing.each do |exchange|
          refresh_cache exchange.receiver, order_cycle
        end
      end
    end

    def self.exchange_changed(exchange)
      if exchange.incoming
        refresh_incoming_exchanges(Exchange.where(id: exchange))
      else
        refresh_outgoing_exchange(exchange)
      end
    end

    def self.exchange_destroyed(exchange)
      exchange_changed exchange
    end

    def self.enterprise_fee_changed(enterprise_fee)
      refresh_supplier_fee    enterprise_fee
      refresh_coordinator_fee enterprise_fee
      refresh_distributor_fee enterprise_fee
    end

    def self.distributor_changed(enterprise)
      Exchange.cachable.where(receiver_id: enterprise).each do |exchange|
        refresh_cache exchange.receiver, exchange.order_cycle
      end
    end

    def self.inventory_item_changed(inventory_item)
      exchanges_featuring_variants(inventory_item.variant, distributor: inventory_item.enterprise).each do |exchange|
        refresh_cache exchange.receiver, exchange.order_cycle
      end
    end


    private

    def self.exchanges_featuring_variants(variants, distributor: nil)
      exchanges = Exchange.
        outgoing.
        with_any_variant(variants).
        joins(:order_cycle).
        merge(OrderCycle.dated).
        merge(OrderCycle.not_closed)

      exchanges = exchanges.to_enterprise(distributor) if distributor

      exchanges
    end

    def self.refresh_incoming_exchanges(exchanges)
      incoming_exchanges(exchanges).map do |exchange|
        outgoing_exchanges_with_variants(exchange.order_cycle, exchange.variant_ids)
      end.flatten.uniq.each do |exchange|
        refresh_cache exchange.receiver, exchange.order_cycle
      end
    end

    def self.refresh_outgoing_exchange(exchange)
      if exchange.order_cycle.dated? && !exchange.order_cycle.closed?
        refresh_cache exchange.receiver, exchange.order_cycle
      end
    end

    def self.refresh_supplier_fee(enterprise_fee)
      refresh_incoming_exchanges(enterprise_fee.exchanges)
    end

    def self.refresh_coordinator_fee(enterprise_fee)
      enterprise_fee.order_cycles.each do |order_cycle|
        order_cycle_changed order_cycle
      end
    end

    def self.refresh_distributor_fee(enterprise_fee)
      enterprise_fee.exchange_fees.
        joins(:exchange => :order_cycle).
        merge(Exchange.outgoing).
        merge(OrderCycle.dated).
        merge(OrderCycle.not_closed).
        each do |exf|

        refresh_cache exf.exchange.receiver, exf.exchange.order_cycle
      end
    end

    def self.incoming_exchanges(exchanges)
      exchanges.
        incoming.
        joins(:order_cycle).
        merge(OrderCycle.dated).
        merge(OrderCycle.not_closed)
    end

    def self.outgoing_exchanges_with_variants(order_cycle, variant_ids)
      order_cycle.exchanges.outgoing.
        joins(:exchange_variants).
        where('exchange_variants.variant_id IN (?)', variant_ids)
    end

    def self.refresh_cache(distributor, order_cycle)
      ProductsCacheRefreshment.refresh distributor, order_cycle
    end
  end
end
