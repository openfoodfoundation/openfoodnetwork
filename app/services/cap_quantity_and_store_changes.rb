# frozen_string_literal: true

class CapQuantityAndStoreChanges
  def initialize(order)
    @order = order
  end

  def call
    changes = {}

    order.insufficient_stock_lines.each do |line_item|
      changes[line_item.id] = line_item.quantity
      line_item.cap_quantity_at_stock!
    end

    unavailable_stock_lines_for.each do |line_item|
      changes[line_item.id] = changes[line_item.id] || line_item.quantity
      line_item.update(quantity: 0)

      Spree::OrderInventory.new(order).verify(line_item, order.shipment)
    end

    if changes.present?
      order.line_items.reload
      order.update_order_fees!
    end

    changes
  end

  private

  attr_reader :order

  def unavailable_stock_lines_for
    order.line_items.where('variant_id NOT IN (?)', available_variants_for.select(&:id))
  end

  def available_variants_for
    OrderCycleDistributedVariants.new(order.order_cycle, order.distributor).available_variants
  end
end
