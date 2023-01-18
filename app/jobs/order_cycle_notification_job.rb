# frozen_string_literal: true

# Delivers an email with a report of the order cycle to each of its suppliers
class OrderCycleNotificationJob < ApplicationJob
  def perform(order_cycle_id)
    order_cycle = OrderCycle.find(order_cycle_id)
    order_cycle.suppliers.each do |supplier|
      ProducerMailer.order_cycle_report(supplier, order_cycle).deliver_now
    end
    order_cycle.update_columns mails_sent: true
  end
end
