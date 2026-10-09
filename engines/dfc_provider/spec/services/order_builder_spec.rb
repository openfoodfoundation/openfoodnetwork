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

    it "maps cart state to Held" do
      ofn_order.update_columns(state: "cart", completed_at: nil)
      expect(described_class.build(ofn_order).orderStatus).to eq "dfc-v:Held"
    end

    it "maps canceled state to Cancelled" do
      ofn_order.cancel!
      expect(described_class.build(ofn_order).orderStatus).to eq "dfc-v:Cancelled"
    end
  end

  describe ".apply and .finalise" do
    subject(:apply_and_finalise) {
      described_class.apply(ofn_order, dfc_order) &&
        described_class.finalise(ofn_order, dfc_order) &&
        ofn_order.save!
    }
    let!(:ofn_order) { create(:order, id: 1) }
    let(:dfc_order) {
      DataFoodConsortium::ConnectorV1::Order.new(
        nil,
        orderStatus: DfcLoader.vocabulary("vocabulary").STATES.ORDERSTATE.HELD,
      )
    }

    it "doesn't complete an order without line items" do
      apply_and_finalise
      expect(ofn_order.reload.state).to eq "cart"
    end

    context "with OrderLines" do
      let!(:variant) { create(:variant, id: 10_000) }
      let!(:variant2) { create(:variant, id: 10_001) }
      let!(:existing_line_item) {
        create(:line_item, order: ofn_order, variant:, quantity: 2)
      }

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

      it "completes the order" do
        apply_and_finalise

        ofn_order.reload
        expect(ofn_order.state).to eq "complete"

        # An order without completed_at is not complete to the rest of OFN: it
        # can't be cancelled and it shows up as the user's shopping cart.
        expect(ofn_order).to be_completed
        expect(ofn_order.shipments).to be_present
      end

      it "creates line items" do
        apply_and_finalise

        expect(ofn_order.line_items.count).to eq 2
        li1 = ofn_order.line_items.find_by!(variant:)
        expect(li1.quantity).to eq 3
        li2 = ofn_order.line_items.find_by!(variant: variant2)
        expect(li2.quantity).to eq 5
      end

      it "updates the quantity of an existing line item" do
        apply_and_finalise
        li = ofn_order.line_items.find_by!(variant:)
        expect(li.quantity).to eq 3
      end

      it "deletes omitted line items" do
        dfc_order.lines = []
        apply_and_finalise
        expect(ofn_order.line_items.reload.count).to eq 0
      end

      it "only changes the order in memory, the caller persists it" do
        described_class.apply(ofn_order, dfc_order)

        # Neither the extra line item nor the new quantity is in the database:
        expect(ofn_order.line_items.reload.count).to eq 1
        expect(ofn_order.line_items.first.quantity).to eq 2
      end

      it "rejects unknown products without touching the order" do
        dfc_order.lines = [
          DataFoodConsortium::ConnectorV1::OrderLine.new(
            nil,
            offer: DataFoodConsortium::ConnectorV1::Offer.new(
              nil, offeredItem: "http://test.host/api/dfc/enterprises/blah/supplied_products/99999"
            ),
            quantity: 1
          ),
        ]

        expect(described_class.apply(ofn_order, dfc_order)).to be false
        expect(ofn_order.errors[:line_items]).to be_present
        expect(ofn_order.line_items.reload.map(&:quantity)).to eq [2]
      end
    end
  end
end
