# frozen_string_literal: true

require 'spec_helper'

describe OrderCycleNotificationJob do
  let(:order_cycle) { create(:order_cycle) }
  let(:mail) { double(:mail, deliver_now: true) }

  before do
    allow(ProducerMailer).to receive(:order_cycle_report).twice.and_return(mail)
  end

  it "sends a mail to each supplier" do
    OrderCycleNotificationJob.perform_now order_cycle.id
    expect(ProducerMailer).to have_received(:order_cycle_report).twice
  end

  it "records that mails have been sent for the order cycle" do
    expect do
      OrderCycleNotificationJob.perform_now(order_cycle.id)
    end.to change{ order_cycle.reload.mails_sent? }.from(false).to(true)
  end
end
