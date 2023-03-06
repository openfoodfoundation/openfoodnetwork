# frozen_string_literal: true

require 'order_management/subscriptions/summarizer'

class SubscriptionPlacementJob < ApplicationJob
  def perform
    proxy_orders.each do |proxy_order|
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
      .order(:id)
  end

  def place_order_for(proxy_order)
    PlaceProxyOrder.new(proxy_order, summarizer, JobLogger.logger, CapQuantity.new).call
  end
end
