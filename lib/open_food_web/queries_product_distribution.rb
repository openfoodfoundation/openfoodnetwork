module OpenFoodWeb
  class QueriesProductDistribution
    def self.active_distributors
      (active_distributors_for_product_distributions + active_distributors_for_order_cycles).sort_by { |d| d.name }.uniq
    end

    def self.products_available_for(products, distributor=nil, order_cycle=nil)
      products = products.in_distributor(distributor) if distributor
      products = products.in_order_cycle(order_cycle) if order_cycle
      products
    end


    private

    def self.active_distributors_for_product_distributions
      Enterprise.is_distributor.with_distributed_active_products_on_hand.by_name
    end

    def self.active_distributors_for_order_cycles
      # Can I create this with merge scopes?
      # ie. Enterprise.is_distributor.join(:order_cycle_distributor).merge(OrderCycle.active)

      # Try this:
      Enterprise.joins('LEFT INNER JOIN exchanges ON (exchanges.receiver_id = enterprises.id)').joins('LEFT INNER JOIN order_cycles ON (order_cycles.id = exchanges.order_cycle.id)').
        merge(OrderCycle.active).select('DISTINCT enterprises.*')

      # Then I can make each of these methods into a scope on Enterprise, and ultimately a single scope
      # Then we don't need this class.

      OrderCycle.active.map { |oc| oc.distributors }.flatten.uniq
    end

  end
end
