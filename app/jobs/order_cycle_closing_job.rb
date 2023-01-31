# frozen_string_literal: true

class OrderCycleClosingJob < ApplicationJob
  def perform
    return if recently_closed_order_cycles.empty?

    send_notifications
    mark_as_processed
  end

  private

  def recently_closed_order_cycles
    @recently_closed_order_cycles ||= OrderCycle.closed.unprocessed.
      where(
        'order_cycles.orders_close_at BETWEEN (?) AND (?)', 1.hour.ago, Time.zone.now
      ).select(:id, :automatic_notifications).to_a
  end

  def send_notifications
    recently_closed_order_cycles.each do |oc|
      OrderCycleNotificationJob.perform_later(oc.id) if oc.automatic_notifications?
    end
  end

  def mark_as_processed
    OrderCycle.where(id: recently_closed_order_cycles).update_all(
      processed_at: Time.zone.now,
      updated_at: Time.zone.now
    )
  end
end
