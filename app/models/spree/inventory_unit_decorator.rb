module Spree
  InventoryUnit.class_eval do
    def self.assign_opening_inventory(order)
      return [] unless order.completed?

      #increase inventory to meet initial requirements
      order.line_items.each do |line_item|
        # Scope variant to hub so that stock levels may be subtracted from VariantOverride.
        line_item.variant.scope_to_hub order.distributor

        increase(order, line_item.variant, line_item.quantity)
      end
    end
  end
end
