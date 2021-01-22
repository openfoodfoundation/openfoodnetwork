# frozen_string_literal: true

require 'spec_helper'

describe CustomerOrderCancellation do
  let(:mail_mock) { double(:mailer_mock, deliver_later: true) }
  before do
    allow(Spree::OrderMailer).to receive(:cancel_email_for_shop) { mail_mock }
  end

  context "when an order is cancelled successfully" do
    it "notifies the distributor by email" do
      order = create(:order, completed_at: Time.now, state: 'complete')

      CustomerOrderCancellation.new(order).call

      expect(Spree::OrderMailer).to have_received(:cancel_email_for_shop).with(order)
      expect(mail_mock).to have_received(:deliver_later)
    end
  end

  context "when the order fails to cancel" do
    it "doesn't notify the distributor by email" do
      order = create(:order, state: 'canceled')

      CustomerOrderCancellation.new(order).call

      expect(Spree::OrderMailer).to_not have_received(:cancel_email_for_shop)
    end
  end
end
