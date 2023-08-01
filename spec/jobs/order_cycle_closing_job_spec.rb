# frozen_string_literal: true

require 'spec_helper'

describe OrderCycleClosingJob do
  let(:order_cycle1) {
    create(:order_cycle, automatic_notifications: true, orders_close_at: 1.minute.ago)
  }
  let(:order_cycle2) {
    create(:order_cycle, automatic_notifications: true, orders_close_at: 1.minute.from_now)
  }
  let(:order_cycle3) {
    create(:order_cycle, automatic_notifications: false, orders_close_at: 1.minute.ago)
  }

  it "sends notifications for recently closed order cycles with automatic notifications enabled" do
    expect(OrderCycleNotificationJob).to receive(:perform_later).with(order_cycle1.id)
    expect(OrderCycleNotificationJob).to_not receive(:perform_later).with(order_cycle2.id)
    expect(OrderCycleNotificationJob).to_not receive(:perform_later).with(order_cycle3.id)

    OrderCycleClosingJob.perform_now
  end

  it "marks order cycles as processed" do
    expect{ OrderCycleClosingJob.perform_now }.to change{ order_cycle1.reload.processed_at }
  end
end
