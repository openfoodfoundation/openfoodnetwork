# frozen_string_literal: true

# Trigger jobs for any order cycles that recently opened
class TriggerOrderCyclesToOpenJob < ApplicationJob
  def perform
    recently_opened_order_cycles.find_each do |order_cycle|
      OpenOrderCycleJob.perform_later(order_cycle.id)
    end
  end

  private

  def recently_opened_order_cycles
    OrderCycle
      .where(opened_at: nil)
      .where(orders_open_at: 1.hour.ago..Time.zone.now)
  end
end
