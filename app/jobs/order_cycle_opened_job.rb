# frozen_string_literal: true

# Trigger jobs for any order cycles that recently opened
class OrderCycleOpenedJob < ApplicationJob
  def perform
    ActiveRecord::Base.transaction do
      recently_opened_order_cycles.find_each do |order_cycle|
        OrderCycleWebhookService.create_webhook_job(order_cycle, 'order_cycle.opened')
      end
      mark_as_opened(recently_opened_order_cycles)
    end
  end

  private

  def recently_opened_order_cycles
    @recently_opened_order_cycles ||= OrderCycle
      .where(opened_at: nil)
      .where(orders_open_at: 1.hour.ago..Time.zone.now)
      .lock.order(:id)
  end

  def mark_as_opened(order_cycles)
    now = Time.zone.now
    order_cycles.update_all(opened_at: now, updated_at: now)
  end
end
