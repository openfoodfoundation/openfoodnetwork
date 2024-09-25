# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BackorderMailer do
  let(:order) { create(:completed_order_with_totals) }
  let(:variants) { order.line_items.map(&:variant) }

  describe "#backorder_failed" do
    it "notifies the owner" do
      order.distributor.owner.email = "jane@example.net"

      BackorderMailer.backorder_failed(order, variants).deliver_now

      mail = ActionMailer::Base.deliveries.first
      expect(mail.to).to eq ["jane@example.net"]
      expect(mail.subject).to eq "An automatic backorder failed"
    end
  end
end
