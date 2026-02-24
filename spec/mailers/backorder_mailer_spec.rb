# frozen_string_literal: true

RSpec.describe BackorderMailer do
  let(:order) { create(:completed_order_with_totals) }

  describe "#backorder_failed" do
    subject(:mail) { described_class.backorder_failed(order) }

    it "notifies the owner" do
      order.distributor.owner.email = "jane@example.net"

      BackorderMailer.backorder_failed(order).deliver_now

      first_mail = ActionMailer::Base.deliveries.first
      expect(first_mail.to).to eq ["jane@example.net"]
      expect(first_mail.subject).to eq "An automatic backorder failed"
    end

    context "white labelling" do
      it_behaves_like 'email with inactive white labelling', :mail
      it_behaves_like 'non-customer facing email with active white labelling', :mail
    end
  end

  describe "#backorder_incomplete" do
    subject(:mail) {
      described_class.backorder_incomplete(
        user, distributor, order_cycle, order_id
      )
    }
    let(:user) { build(:user, email: "jane@example.net") }
    let(:distributor) { build(:enterprise) }
    let(:order_cycle) { build(:order_cycle) }
    let(:order_id) { "https://null" }

    it "notifies the owner" do
      BackorderMailer.backorder_incomplete(user, distributor, order_cycle, order_id).deliver_now

      first_mail = ActionMailer::Base.deliveries.first
      expect(first_mail.to).to eq ["jane@example.net"]
      expect(first_mail.subject).to eq "An automatic backorder failed to complete"
    end

    context "white labelling" do
      it_behaves_like 'email with inactive white labelling', :mail
      it_behaves_like 'non-customer facing email with active white labelling', :mail
    end
  end
end
