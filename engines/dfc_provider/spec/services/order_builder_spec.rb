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
      DataFoodConsortium::ConnectorV1::Order.new(
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
      let!(:variant2) { create(:variant, id: 10_001) }

      before do
        offer1 = DataFoodConsortium::ConnectorV1::Offer.new(
          nil, offeredItem: "http://test.host/api/dfc/enterprises/blah/supplied_products/10000"
        )
        offer2 = DataFoodConsortium::ConnectorV1::Offer.new(
          nil, offeredItem: "http://test.host/api/dfc/enterprises/blah/supplied_products/10001"
        )
        order_line1 = DataFoodConsortium::ConnectorV1::OrderLine.new(
          nil, offer: offer1, quantity: 3
        )
        order_line2 = DataFoodConsortium::ConnectorV1::OrderLine.new(
          nil, offer: offer2, quantity: 5
        )

        dfc_order.lines = [order_line1, order_line2]
      end

      it "creates line items" do
        expect(subject).to be true

        expect(ofn_order.line_items.count).to eq 2
        li1 = ofn_order.line_items.find_by!(variant:)
        expect(li1.quantity).to eq 3
        li2 = ofn_order.line_items.find_by!(variant: variant2)
        expect(li2.quantity).to eq 5
      end
    end
  end

  describe ".line_item_attributes" do
    let!(:ofn_order) { create(:order, id: 1) }
    let!(:existing_variant) { create(:variant, id: 101_000, on_demand: true) }
    let!(:existing_line_item) {
      create(:line_item, order: ofn_order, variant: existing_variant, quantity: 2)
    }

    let(:dfc_order) {
      order = DataFoodConsortium::ConnectorV1::Order.new(nil)
      offer = DataFoodConsortium::ConnectorV1::Offer.new(
        nil, offeredItem: "http://test.host/api/dfc/enterprises/blah/supplied_products/101000"
      )
      order.lines = [
        DataFoodConsortium::ConnectorV1::OrderLine.new(nil, offer:, quantity: 5),
      ]
      order
    }

    subject(:attributes) { described_class.line_item_attributes(ofn_order, dfc_order) }

    it "updates the quantity of an existing line item" do
      expect(attributes.find { |a| a[:id] == existing_line_item.id }[:quantity]).to eq 5
    end

    it "creates line items for new variants" do
      offer = DataFoodConsortium::ConnectorV1::Offer.new(
        nil, offeredItem: "http://test.host/api/dfc/enterprises/blah/supplied_products/101001"
      )
      dfc_order.lines << DataFoodConsortium::ConnectorV1::OrderLine.new(nil, offer:, quantity: 3)

      expect(attributes).to include(variant_id: 101_001, quantity: 3)
    end

    it "marks omitted line items for destruction" do
      dfc_order.lines = []

      expect(attributes.find { |a| a[:id] == existing_line_item.id }[:_destroy]).to eq true
    end
  end
end
