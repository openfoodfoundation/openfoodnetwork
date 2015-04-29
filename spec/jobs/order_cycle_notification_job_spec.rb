require 'spec_helper'

describe OrderCycleNotificationJob do
  let(:order_cycle) { create(:order_cycle) }

  it "sends a mail to each supplier" do
    mail = double(:mail)
    allow(mail).to receive(:deliver)
    expect(ProducerMailer).to receive(:order_cycle_report).twice.and_return(mail)
    run_job OrderCycleNotificationJob.new(order_cycle.id)
  end
end
