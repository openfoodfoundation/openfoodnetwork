require 'spec_helper'

describe OrderCycleNotificationJob do
  let(:order_cycle) { create(:order_cycle) }
  let(:mail) { double(:mail, deliver: true) }

  before do
    allow(ProducerMailer).to receive(:order_cycle_report).twice.and_return(mail)
  end

  it 'sends a mail to each supplier' do
    OrderCycleNotificationJob.perform_now order_cycle.id
    expect(ProducerMailer).to have_received(:order_cycle_report).twice
  end
end
