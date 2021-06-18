# frozen_string_literal: true

require 'order_management/subscriptions/summarizer'

class SubscriptionPlacementJob < ActiveJob::Base
  def perform
    ids = proxy_orders.pluck(:id)
    ProxyOrder.where(id: ids).each do |proxy_order|
      place_order_for(proxy_order)
    end

    send_placement_summary_emails
  end

  private

  delegate :record_success, :record_issue, :record_subscription_issue, to: :summarizer
  delegate :record_order, :record_and_log_error, :send_placement_summary_emails, to: :summarizer

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
    JobLogger.logger.info("Placing Order for Proxy Order #{proxy_order.id}")
    initialise_order(proxy_order)
    return unless proxy_order.order.present?

    proxy_order.update_column(:placed_at, Time.zone.now)
    place_order(proxy_order.order)
  end

  def initialise_order(proxy_order)
    proxy_order.initialise_order!
    record_subscription_issue(proxy_order.subscription) if proxy_order.order.nil?
  rescue StandardError => e
    Bugsnag.notify(e, subscription: proxy_order.subscription, proxy_order: proxy_order)
  end

  def place_order(order)
    record_order(order)
    return record_issue(:complete, order) if order.completed?

    changes = cap_quantity_and_store_changes(order)
    return handle_empty_order(order, changes) if order.line_items.where('quantity > 0').empty?

    move_to_completion(order)
    send_placement_email(order, changes)
  rescue StandardError => e
    record_and_log_error(:processing, order, e.message)
    Bugsnag.notify(e, order: order)
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

  def handle_empty_order(order, changes)
    order.reload.all_adjustments.destroy_all
    order.update_order!
    send_empty_email(order, changes)
  end

  def move_to_completion(order)
    OrderWorkflow.new(order).complete!
  end

  def unavailable_stock_lines_for(order)
    order.line_items.where('variant_id NOT IN (?)', available_variants_for(order).select(&:id))
  end

  def available_variants_for(order)
    OrderCycleDistributedVariants.new(order.order_cycle, order.distributor).available_variants
  end

  def send_placement_email(order, changes)
    record_issue(:changes, order) if changes.present?
    record_success(order) if changes.blank?
    SubscriptionMailer.placement_email(order, changes).deliver_now
  end

  def send_empty_email(order, changes)
    record_issue(:empty, order)
    SubscriptionMailer.empty_email(order, changes).deliver_now
  end
end
