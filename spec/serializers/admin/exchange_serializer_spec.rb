require 'open_food_network/order_cycle_permissions'

describe Api::Admin::ExchangeSerializer do
  let(:v1) { create(:variant) }
  let(:v2) { create(:variant) }
  let(:permissions_mock) { double(:permissions) }
  let(:serializer) { Api::Admin::ExchangeSerializer.new exchange }

  context "serializing incoming exchanges" do
    let(:exchange) { create(:exchange, incoming: true, variants: [v1, v2]) }
    let(:permitted_variants) { double(:permitted_variants) }

    before do
      allow(OpenFoodNetwork::OrderCyclePermissions).to receive(:new) { permissions_mock }
      allow(permissions_mock).to receive(:visible_variants_for_incoming_exchanges_from) { Spree::Variant.where(id: [v1]) }
    end

    it "filters variants within the exchange based on permissions" do
      visible_variants = serializer.variants
      expect(permissions_mock).to have_received(:visible_variants_for_incoming_exchanges_from).with(exchange.sender)
      expect(exchange.variants).to include v1, v2
      expect(visible_variants.keys).to include v1.id
      expect(visible_variants.keys).to_not include v2.id
    end
  end

  context "serializing outgoing exchanges" do
    let(:exchange) { create(:exchange, incoming: false, variants: [v1, v2]) }
    let(:permitted_variants) { double(:permitted_variants) }

    before do
      allow(OpenFoodNetwork::OrderCyclePermissions).to receive(:new) { permissions_mock }
      allow(permissions_mock).to receive(:visible_variants_for_outgoing_exchanges_to) { permitted_variants }
    end

    context "when the receiver prefers to see all variants (not just those in their inventory)" do
      before do
        allow(exchange.receiver).to receive(:prefers_product_selection_from_inventory_only?) { false }
        allow(permitted_variants).to receive(:not_hidden_for) { Spree::Variant.where(id: [v1]) }
      end

      it "filters variants within the exchange based on permissions" do
        visible_variants = serializer.variants
        expect(permissions_mock).to have_received(:visible_variants_for_outgoing_exchanges_to).with(exchange.receiver)
        expect(permitted_variants).to have_received(:not_hidden_for).with(exchange.receiver)
        expect(exchange.variants).to include v1, v2
        expect(visible_variants.keys).to include v1.id
        expect(visible_variants.keys).to_not include v2.id
      end
    end

    context "when the receiver prefers to restrict visible variants to only those in their inventory" do
      before do
        allow(exchange.receiver).to receive(:prefers_product_selection_from_inventory_only?) { true }
        allow(permitted_variants).to receive(:visible_for) { Spree::Variant.where(id: [v1]) }
      end

      it "filters variants within the exchange based on permissions, and inventory visibility" do
        visible_variants = serializer.variants
        expect(permissions_mock).to have_received(:visible_variants_for_outgoing_exchanges_to).with(exchange.receiver)
        expect(permitted_variants).to have_received(:visible_for).with(exchange.receiver)
        expect(exchange.variants).to include v1, v2
        expect(visible_variants.keys).to include v1.id
        expect(visible_variants.keys).to_not include v2.id
      end
    end
  end
end
