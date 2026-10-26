# frozen_string_literal: true

RSpec.describe OrderCycleClosingJob do
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
    # existing data
    order_cycle1; order_cycle2; order_cycle3

    expect { OrderCycleClosingJob.perform_now }
      .to enqueue_job(OrderCycleNotificationJob).with(order_cycle1.id)
  end

  it "marks order cycles as processed" do
    expect{ OrderCycleClosingJob.perform_now }.to change{ order_cycle1.reload.processed_at }
  end
end
