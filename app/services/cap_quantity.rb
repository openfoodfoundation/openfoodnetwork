# frozen_string_literal: true

class CapQuantity
  def initialize
    @changes = {}
  end

  def call(order)
    @order = order

    cap_insufficient_stock!
    verify_line_items

    reload_order if changes.present?

    changes
  end

  private

  attr_reader :order, :changes

  def cap_insufficient_stock!
    order.insufficient_stock_lines.each do |line_item|
      changes[line_item.id] = line_item.quantity
      line_item.cap_quantity_at_stock!
    end
  end

  def verify_line_items
    unavailable_stock_lines_for.each do |line_item|
      changes[line_item.id] = changes[line_item.id] || line_item.quantity
      line_item.update(quantity: 0)

      Spree::OrderInventory.new(order).verify(line_item, order.shipment)
    end
  end

  def reload_order
    order.line_items.reload
    order.update_order_fees!
  end

  def unavailable_stock_lines_for
    order.line_items.where('variant_id NOT IN (?)', available_variants_for.select(&:id))
  end

  def available_variants_for
    OrderCycleDistributedVariants.new(order.order_cycle, order.distributor).available_variants
  end
end
