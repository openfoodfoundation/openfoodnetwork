module OpenFoodWeb
  class QueriesProductDistribution
    def self.active_distributors
      (active_distributors_for_product_distributions + active_distributors_for_order_cycles).sort_by { |d| d.name }.uniq
    end


    private

    def self.active_distributors_for_product_distributions
      Enterprise.is_distributor.with_distributed_active_products_on_hand.by_name
    end

    def self.active_distributors_for_order_cycles
      OrderCycle.active.map { |oc| oc.distributors }.flatten.uniq
    end

  end
end
