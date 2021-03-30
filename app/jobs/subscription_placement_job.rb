# frozen_string_literal: true

require 'order_management/subscriptions/summarizer'

class SubscriptionPlacementJob < ActiveJob::Base
  def perform
    ids = proxy_orders.pluck(:id)
    ProxyOrder.where(id: ids).each do |proxy_order|
      place_order_for(proxy_order)
    end

    summarizer.send_placement_summary_emails
  end

  private

  def summarizer
    @summarizer ||= OrderManagement::Subscriptions::Summarizer.new
  end

  def proxy_orders
    # Loads proxy orders for open order cycles that have not been placed yet
    ProxyOrder.not_canceled.where(placed_at: nil)
      .joins(:order_cycle).merge(OrderCycle.active)
      .joins(:subscription).merge(Subscription.not_canceled.not_paused)
  end

  def place_order_for(proxy_order)
    place_order = PlaceOrder.new(
      proxy_order,
      summarizer,
      JobLogger.logger,
      lambda { cap_quantity_and_store_changes(proxy_order.order) }
    )

    place_order.call
  end

  def cap_quantity_and_store_changes(order)
    changes = {}
    order.insufficient_stock_lines.each do |line_item|
      changes[line_item.id] = line_item.quantity
      line_item.cap_quantity_at_stock!
    end
    unavailable_stock_lines_for(order).each do |line_item|
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

  def unavailable_stock_lines_for(order)
    order.line_items.where('variant_id NOT IN (?)', available_variants_for(order).select(&:id))
  end

  def available_variants_for(order)
    OrderCycleDistributedVariants.new(order.order_cycle, order.distributor).available_variants
  end
end
