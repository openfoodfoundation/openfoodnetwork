# frozen_string_literal: true

require 'spec_helper'
require 'open_food_network/order_cycle_permissions'

describe Api::Admin::ExchangeSerializer do
  let(:v1) { create(:variant) }
  let(:v2) { create(:variant) }
  let(:v3) { create(:variant) }
  let(:permissions_mock) { double(:permissions) }
  let(:permitted_variants) { Spree::Variant.where(id: [v1, v2]) }
  let(:serializer) { Api::Admin::ExchangeSerializer.new exchange }

  context "serializing incoming exchanges" do
    let(:exchange) { create(:exchange, incoming: true, variants: [v1, v2, v3]) }
    let!(:inventory_item) {
      create(:inventory_item, enterprise: exchange.order_cycle.coordinator, variant: v1,
                              visible: true)
    }

    before do
      allow(OpenFoodNetwork::OrderCyclePermissions).to receive(:new) { permissions_mock }
      allow(permissions_mock).to receive(:visible_variants_for_incoming_exchanges_from) {
                                   permitted_variants
                                 }
      allow(permitted_variants).to receive(:visible_for).and_call_original
    end

    context "when order cycle shows only variants in the coordinator's inventory" do
      before do
        allow(exchange.order_cycle)
          .to receive(:prefers_product_selection_from_coordinator_inventory_only?) { true }
      end

      it "filters variants within the exchange based on permissions, and visibility in inventory" do
        visible_variants = serializer.variants
        expect(permissions_mock).to have_received(:visible_variants_for_incoming_exchanges_from)
          .with(exchange.sender)
        expect(permitted_variants).to have_received(:visible_for)
          .with(exchange.order_cycle.coordinator)
        expect(exchange.variants).to include v1, v2, v3
        expect(visible_variants.keys).to include v1.id
        expect(visible_variants.keys).to_not include v2.id, v3.id
      end
    end

    context "when order cycle shows all available products" do
      before do
        allow(exchange.order_cycle)
          .to receive(:prefers_product_selection_from_coordinator_inventory_only?) { false }
      end

      it "filters variants within the exchange based on permissions only" do
        visible_variants = serializer.variants
        expect(permissions_mock).to have_received(:visible_variants_for_incoming_exchanges_from)
          .with(exchange.sender)
        expect(permitted_variants).to_not have_received(:visible_for)
        expect(exchange.variants).to include v1, v2, v3
        expect(visible_variants.keys).to include v1.id, v2.id
        expect(visible_variants.keys).to_not include v3.id
      end
    end
  end

  context "serializing outgoing exchanges" do
    let(:exchange) { create(:exchange, incoming: false, variants: [v1, v2, v3]) }
    let!(:inventory_item) {
      create(:inventory_item, enterprise: exchange.receiver, variant: v1, visible: true)
    }

    before do
      allow(OpenFoodNetwork::OrderCyclePermissions).to receive(:new) { permissions_mock }
      allow(permissions_mock).to receive(:visible_variants_for_outgoing_exchanges_to) {
                                   permitted_variants
                                 }
      allow(permitted_variants).to receive(:visible_for).and_call_original
      allow(permitted_variants).to receive(:not_hidden_for).and_call_original
    end

    context "when the receiver prefers to see all variants (not just those in their inventory)" do
      before do
        allow(exchange.receiver)
          .to receive(:prefers_product_selection_from_inventory_only?) { false }
      end

      it "filters variants within the exchange based on permissions only" do
        visible_variants = serializer.variants
        expect(permissions_mock).to have_received(:visible_variants_for_outgoing_exchanges_to)
          .with(exchange.receiver)
        expect(permitted_variants).to have_received(:not_hidden_for).with(exchange.receiver)
        expect(permitted_variants).to_not have_received(:visible_for)
        expect(exchange.variants).to include v1, v2, v3
        expect(visible_variants.keys).to include v1.id, v2.id
        expect(visible_variants.keys).to_not include v3.id
      end
    end

    context "when the receiver prefers to restrict visible variants " \
            "to only those in their inventory" do
      before do
        allow(exchange.receiver)
          .to receive(:prefers_product_selection_from_inventory_only?) { true }
      end

      it "filters variants within the exchange based on permissions, and inventory visibility" do
        visible_variants = serializer.variants
        expect(permissions_mock).to have_received(:visible_variants_for_outgoing_exchanges_to)
          .with(exchange.receiver)
        expect(permitted_variants).to have_received(:visible_for).with(exchange.receiver)
        expect(permitted_variants).to_not have_received(:not_hidden_for)
        expect(exchange.variants).to include v1, v2, v3
        expect(visible_variants.keys).to include v1.id
        expect(visible_variants.keys).to_not include v2.id, v3.id
      end
    end
  end
end
