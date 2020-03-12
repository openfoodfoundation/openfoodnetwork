module Spree
  Shipment.class_eval do
    def ensure_correct_adjustment_with_included_tax
      ensure_correct_adjustment_without_included_tax

      update_adjustment_included_tax if adjustment
    end
    alias_method_chain :ensure_correct_adjustment, :included_tax

    def update_adjustment_included_tax
      if Config.shipment_inc_vat && (order.distributor.nil? || order.distributor.charges_sales_tax)
        adjustment.set_included_tax! Config.shipping_tax_rate
      else
        adjustment.set_included_tax! 0
      end
    end

    def manifest
      inventory_units.group_by(&:variant).map do |variant, units|
        states = {}
        units.group_by(&:state).each { |state, iu| states[state] = iu.count }
        scoper.scope(variant)
        OpenStruct.new(variant: variant, quantity: units.length, states: states)
      end
    end

    def scoper
      @scoper ||= OpenFoodNetwork::ScopeVariantToHub.new(order.distributor)
    end

    private

    # NOTE: This is an override of spree's method, needed to allow orders
    # without line items (ie. user invoices) to not have inventory units
    def require_inventory
      return false unless line_items.count > 0 # This line altered

      order.completed? && !order.canceled?
    end
  end
end
