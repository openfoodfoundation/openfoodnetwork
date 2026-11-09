# frozen_string_literal: true

class CapQuantity
  def initialize
    @changes = {}
    @affected_line_items = []
  end

  def call(order)
    @order = order

    cap_insufficient_stock!
    verify_line_items

    reload_order if changes.present?

    changes
  end

  private

  attr_reader :order, :changes, :affected_line_items

  def cap_insufficient_stock!
    order.insufficient_stock_lines.each do |line_item|
      changes[line_item.id] = line_item.quantity
      line_item.cap_quantity_at_stock!
      affected_line_items << line_item
    end
  end

  def verify_line_items
    unavailable_stock_lines_for.each do |line_item|
      changes[line_item.id] = changes[line_item.id] || line_item.quantity
      line_item.update(quantity: 0)

      Spree::OrderInventory.new(order).verify(line_item, order.shipment)
      affected_line_items << line_item
    end
  end

  def reload_order
    order.line_items.reload
    # Line item quantities may have changed above, which can change the amount
    # of any per-item enterprise fees applied to them (eg to zero, when a line
    # item's quantity has been capped to zero because it is out of stock).
    # `update_order_fees!` only updates fees applied to the order as a whole,
    # so line item fees need to be refreshed separately here.
    affected_line_items.each { |line_item| order.update_line_item_fees!(line_item) }
    order.update_order_fees!
  end

  def unavailable_stock_lines_for
    order.line_items.where.not(variant_id: available_variants_for.select(&:id))
  end

  def available_variants_for
    OrderCycles::DistributedVariantsService.new(order.order_cycle,
                                                order.distributor).available_variants
  end
end
