# frozen_string_literal: true

RSpec.describe OrderCycleNotificationJob do
  let(:order_cycle) { create(:order_cycle) }

  it "sends a mail to each supplier" do
    expect {
      OrderCycleNotificationJob.perform_now(order_cycle.id)
    }.to enqueue_mail(ProducerMailer, :order_cycle_report).twice
  end

  it "records that mails have been sent for the order cycle" do
    expect {
      OrderCycleNotificationJob.perform_now(order_cycle.id)
    }.to change {
      order_cycle.reload.mails_sent?
    }.from(false).to(true)
  end
end
