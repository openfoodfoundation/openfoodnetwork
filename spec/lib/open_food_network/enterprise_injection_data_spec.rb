# frozen_string_literal: true

require 'open_food_network/enterprise_injection_data'

RSpec.describe OpenFoodNetwork::EnterpriseInjectionData do
  let(:enterprise1) { create :distributor_enterprise, with_payment_and_shipping: true }
  let(:enterprise2) { create :distributor_enterprise, with_payment_and_shipping: true }
  let(:enterprise3) { create :distributor_enterprise, with_payment_and_shipping: true }
  let(:enterprise4) { create :distributor_enterprise, with_payment_and_shipping: true }

  before do
    [enterprise1, enterprise2, enterprise3].each do |ent|
      create :open_order_cycle, distributors: [ent]
    end
  end

  let!(:closed_oc) { create :closed_order_cycle, coordinator: enterprise4 }

  context "when scoped to specific enterprises" do
    subject {
      described_class.new([enterprise1.id, enterprise2.id])
    }

    describe "#active_distributor_ids" do
      it "should include enterprise1.id and enterprise2.id" do
        ids = subject.active_distributor_ids
        expect(ids).to include enterprise1.id
        expect(ids).to include enterprise2.id
        expect(ids).not_to include enterprise3.id
      end
    end
  end

  context "when unscoped to specific enterprises" do
    let(:subject) { described_class.new }

    describe "#active_distributor_ids" do
      it "should include all enterprise ids" do
        ids = subject.active_distributor_ids
        expect(ids).to include enterprise1.id
        expect(ids).to include enterprise2.id
        expect(ids).to include enterprise3.id
      end
    end
  end
end
