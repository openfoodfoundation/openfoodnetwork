module OpenFoodNetwork

  # When elements of the data model change, enqueue jobs to refresh the appropriate parts of
  # the products cache.
  class ProductsCache
    def self.variant_changed(variant)
      exchanges_featuring_variant(variant).each do |exchange|
        refresh_cache exchange.receiver, exchange.order_cycle
      end
    end


    def self.variant_destroyed(variant, &block)
      exchanges = exchanges_featuring_variant(variant).to_a

      block.call

      exchanges.each do |exchange|
        refresh_cache exchange.receiver, exchange.order_cycle
      end
    end


    private

    def self.exchanges_featuring_variant(variant)
      Exchange.
        outgoing.
        with_variant(variant).
        joins(:order_cycle).
        merge(OrderCycle.dated).
        merge(OrderCycle.not_closed)
    end


    def self.refresh_cache(distributor, order_cycle)
      Delayed::Job.enqueue RefreshProductsCacheJob.new distributor.id, order_cycle.id
    end
  end
end
