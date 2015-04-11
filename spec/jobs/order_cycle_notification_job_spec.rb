require 'spec_helper'

describe OrderCycleNotificationJob do
  let(:order_cycle) { create(:order_cycle) }

  it 'sends a mail to each supplier' do
    mail = double()
    allow(mail).to receive(:deliver)
    mailer = double('ProducerMailer')
    expect(ProducerMailer).to receive(:order_cycle_report).twice.and_return(mail)
    job = OrderCycleNotificationJob.new(order_cycle)
    job.perform
  end
end
