# frozen_string_literal: true

RSpec.describe BackorderMailer do
  let(:order) { create(:completed_order_with_totals) }

  describe "#backorder_failed" do
    it "notifies the owner" do
      order.distributor.owner.email = "jane@example.net"

      BackorderMailer.backorder_failed(order).deliver_now

      mail = ActionMailer::Base.deliveries.first
      expect(mail.to).to eq ["jane@example.net"]
      expect(mail.subject).to eq "An automatic backorder failed"
    end
  end

  describe "#backorder_incomplete" do
    let(:user) { build(:user, email: "jane@example.net") }
    let(:distributor) { build(:enterprise) }
    let(:order_cycle) { build(:order_cycle) }
    let(:order_id) { "https://null" }

    it "notifies the owner" do
      BackorderMailer.backorder_incomplete(user, distributor, order_cycle, order_id).deliver_now

      mail = ActionMailer::Base.deliveries.first
      expect(mail.to).to eq ["jane@example.net"]
      expect(mail.subject).to eq "An automatic backorder failed to complete"
    end
  end
end
