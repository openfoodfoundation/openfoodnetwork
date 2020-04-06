module Spree
  Shipment.class_eval do
    def ensure_correct_adjustment
      if adjustment
        adjustment.originator = shipping_method
        adjustment.label = shipping_method.adjustment_label
        adjustment.amount = selected_shipping_rate.cost if adjustment.open?
        adjustment.save!
        adjustment.reload
      elsif selected_shipping_rate_id
        shipping_method.create_adjustment shipping_method.adjustment_label, order, self, true, "open"
        reload #ensure adjustment is present on later saves
      end

      update_adjustment_included_tax if adjustment
    end

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
