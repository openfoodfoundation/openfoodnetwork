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

  describe ".apply" do
    subject { described_class.apply(ofn_order, dfc_order) }
    let!(:ofn_order) { create(:order, id: 1) }
    let(:dfc_order) {
      DataFoodConsortium::Connector::Order.new(
        nil,
        orderStatus: DfcLoader.vocabulary("vocabulary").STATES.ORDERSTATE.HELD,
      )
    }

    it "applies attribute changes to order" do
      expect(subject).to be true
      expect(ofn_order.state).to eq "complete"
    end

    context "with OrderLines" do
      let!(:variant) { create(:variant, id: 10_000) }

      before do
        offer = DataFoodConsortium::Connector::Offer.new(
          nil, offeredItem: "http://test.host/api/dfc/enterprises/blah/supplied_products/10000"
        )
        order_line = DataFoodConsortium::Connector::OrderLine.new(
          nil, offer:, quantity: 3
        )

        dfc_order.lines = [order_line, order_line]
      end

      it "creates line items" do
        expect(subject).to be true

        expect(ofn_order.line_items.count).to eq 2
        expect(ofn_order.line_items.first.variant).to eq variant
        expect(ofn_order.line_items.first.quantity).to eq 3
      end
    end
  end
end
