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
      line_item = add_to_line_item(variant, quantity, shipment)
      update_shipment(shipment)
      update_order
      line_item
    end

    # Get current line item for variant
    # Remove variant qty from line_item
    def remove(variant, quantity = nil, shipment = nil, restock_item = true)
      line_item = remove_from_line_item(variant, quantity, shipment, restock_item)
      update_shipment(shipment)
      order.update_order_fees! if order.completed?
      update_order
      line_item
    end

    def update_or_create(variant, attributes)
      line_item = find_line_item_by_variant(variant)

      if line_item
        line_item.update(attributes)
      else
        line_item = Spree::LineItem.new(attributes)
        line_item.variant = variant
        line_item.price = variant.price
        order.line_items << line_item
      end

      order.reload
      line_item
    end

    def update_cart(params)
      if order.update(params)
        discard_empty_line_items
        update_shipment
        update_order
        true
      else
        false
      end
    end

    def update_item(line_item, params)
      if line_item.update(params)
        discard_empty_line_items
        order.update_line_item_fees! line_item
        order.update_order_fees! if order.completed?
        update_shipment
        update_order
        true
      else
        false
      end
    end

    private

    def discard_empty_line_items
      order.line_items = order.line_items.select { |li| li.quantity.positive? }
    end

    def update_shipment(target_shipment = nil)
      if order.completed? || target_shipment.present?
        order.update_shipping_fees!
      else
        order.ensure_updated_shipments
      end
    end

    def add_to_line_item(variant, quantity, shipment = nil)
      line_item = find_line_item_by_variant(variant)

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

    def remove_from_line_item(variant, quantity, shipment = nil, restock_item = true)
      line_item = find_line_item_by_variant(variant, true)
      line_item.restock_item = restock_item
      quantity.present? ? line_item.quantity += -quantity : line_item.quantity = 0
      line_item.target_shipment = shipment

      if line_item.quantity == 0
        line_item.destroy
      else
        line_item.save!
      end

      line_item
    end

    def find_line_item_by_variant(variant, raise_error = false)
      line_item = order.find_line_item_by_variant(variant)

      if !line_item.present? && raise_error
        raise ActiveRecord::RecordNotFound, "Line item not found for variant #{variant.sku}"
      end

      line_item
    end

    def update_order
      order.update_order!
      order.reload
    end
  end
end
