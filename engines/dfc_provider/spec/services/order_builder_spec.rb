# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe OrderBuilder do
  describe ".new_order" do
    subject(:result) { described_class.new_order(ofn_order) }
    let(:ofn_order) {
      create(
        :completed_order_with_totals,
        id: 1,
      )
    }

    it "builds a new order" do
      expect(result.semanticId).to eq nil
      expect(result.lines.count).to eq 0
      expect(result.orderStatus).to eq "dfc-v:Held"
    end
  end

  describe '.build' do
    let(:distributor) { create(:distributor_enterprise, id: 10_000) }
    let(:ofn_order) { create(:completed_order_with_totals, distributor:, id: 1) }
    subject(:result) { described_class.build(ofn_order) }

    it "builds and stores a DFC order object" do
      expect(result.semanticId).to  eq "http://test.host/api/dfc/enterprises/10000/orders/1"
      expect(result.client).to      eq "http://test.host/api/dfc/enterprises/10000"
      expect(result.orderStatus).to eq "dfc-v:Held"
      expect(result.lines.count).to eq 0
    end
  end
end
