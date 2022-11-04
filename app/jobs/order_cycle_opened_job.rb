# frozen_string_literal: true

# Trigger jobs for any order cycles that recently opened
class OrderCycleOpenedJob < ApplicationJob
  def perform
    recently_opened_order_cycles.each do |order_cycle|
      OrderCycleWebhookService.create_webhook_job(order_cycle, 'order_cycle.opened')
    end
  end

  private

  def recently_opened_order_cycles
    OrderCycle
      .where(orders_open_at: 1.hour.ago..Time.zone.now)
  end
end
