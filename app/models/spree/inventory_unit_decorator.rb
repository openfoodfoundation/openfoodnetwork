module Spree
  InventoryUnit.class_eval do
    def self.assign_opening_inventory(order)
      return [] unless order.completed?

      #increase inventory to meet initial requirements
      scoper = OpenFoodNetwork::ScopeVariantToHub.new(order.distributor)
      order.line_items.each do |line_item|
        # Scope variant to hub so that stock levels may be subtracted from VariantOverride.
        scoper.scope(line_item.variant)

        increase(order, line_item.variant, line_item.quantity)
      end
    end
  end
end
