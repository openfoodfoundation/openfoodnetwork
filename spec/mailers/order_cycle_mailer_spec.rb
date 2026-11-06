# frozen_string_literal: true

RSpec.describe OrderCycleMailer do
  describe "#producer_selection_updated" do
    subject(:mail) { described_class.producer_selection_updated(order_cycle, producer) }
    let(:coordinator) { create(:distributor_enterprise) }
    let(:producer) { create(:supplier_enterprise, name: "Fred's Farm") }
    let(:order_cycle) { create(:simple_order_cycle, coordinator:, suppliers: [producer]) }

    it "notifies the coordinator" do
      expect(mail.to).to eq [coordinator.contact.email]
      expect(mail.reply_to).to eq [producer.contact.email]
    end

    it "tells which producer updated their product selection" do
      expect(mail.subject).to eq "A producer has updated their product selection"
      expect(mail.body).to have_content(
        "Fred's Farm has updated their product selection for the current order cycle."
      )
    end

    it "contains a link to edit the order cycle" do
      expect(mail.body).to have_link(
        "Edit the order cycle",
        href: "http://test.host/admin/order_cycles/#{order_cycle.id}/edit"
      )
    end

    context "white labelling" do
      it_behaves_like 'email with inactive white labelling', :mail
    end
  end
end
