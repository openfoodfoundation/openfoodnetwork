module OpenFoodNetwork

  # When elements of the data model change, enqueue jobs to refresh the appropriate parts of
  # the products cache.
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


    def self.variant_override_changed(variant_override)
      exchanges_featuring_variants(variant_override.variant, distributor: variant_override.hub).each do |exchange|
        refresh_cache exchange.receiver, exchange.order_cycle
      end
    end


    def self.variant_override_destroyed(variant_override)
      variant_override_changed variant_override
    end


    def self.order_cycle_changed(order_cycle)
      if order_cycle.dated? && !order_cycle.closed?
        order_cycle.exchanges.outgoing.each do |exchange|
          refresh_cache exchange.receiver, order_cycle
        end
      end
    end


    def self.enterprise_fee_changed(enterprise_fee)
    end


    def self.enterprise_fee_destroyed(enterprise_fee, &block)
      block.call
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


    def self.refresh_cache(distributor, order_cycle)
      Delayed::Job.enqueue RefreshProductsCacheJob.new distributor.id, order_cycle.id
    end
  end
end
