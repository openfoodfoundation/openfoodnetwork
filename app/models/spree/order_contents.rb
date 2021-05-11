# frozen_string_literal: true

module Spree
  class OrderContents
    attr_accessor :order

    def initialize(order)
      @order = order
    end

    # Get current line item for variant if exists
    # Add variant qty to line_item
    def add(variant, quantity = 1, shipment = nil)
      line_item = order.find_line_item_by_variant(variant)
      add_to_line_item(line_item, variant, quantity, shipment)
      update_shipment(shipment)
      update_order
    end

    # Get current line item for variant
    # Remove variant qty from line_item
    def remove(variant, quantity = 1, shipment = nil)
      line_item = order.find_line_item_by_variant(variant)

      unless line_item
        raise ActiveRecord::RecordNotFound, "Line item not found for variant #{variant.sku}"
      end

      remove_from_line_item(line_item, variant, quantity, shipment)
      update_shipment(shipment)
      update_order
    end

    def update_cart(params)
      if order.update_attributes(params)
        order.line_items = order.line_items.select {|li| li.quantity > 0 }
        order.ensure_updated_shipments
        update_order
        true
      else
        false
      end
    end

    private

    def update_shipment(shipment)
      shipment.present? ? shipment.update_amounts : order.ensure_updated_shipments
    end

    def add_to_line_item(line_item, variant, quantity, shipment = nil)
      if line_item
        line_item.target_shipment = shipment
        line_item.quantity += quantity.to_i
      else
        line_item = order.line_items.new(quantity: quantity, variant: variant)
        line_item.target_shipment = shipment
        line_item.price = variant.price
      end

      line_item.save
      line_item
    end

    def remove_from_line_item(line_item, _variant, quantity, shipment = nil)
      line_item.quantity += -quantity
      line_item.target_shipment = shipment

      if line_item.quantity == 0
        line_item.destroy
      else
        line_item.save!
      end

      line_item
    end

    def update_order
      order.update_order!
      order.reload
    end
  end
end
