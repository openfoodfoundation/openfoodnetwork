# frozen_string_literal: true

require "spec_helper"

module Api
  module Admin
    describe OrderCycleSerializer do
      let(:order_cycle) { create(:order_cycle) }
      let(:serializer) {
        Api::Admin::OrderCycleSerializer.new order_cycle,
                                             current_user: order_cycle.coordinator.owner
      }

      it "serializes an order cycle" do
        expect(serializer.to_json).to include order_cycle.name
      end

      it "serializes the order cycle with exchanges" do
        expect(serializer.exchanges.to_json).to include "\"#{order_cycle.variants.first.id}\":true"
      end

      it "serializes the order cycle with editable_variants_for_incoming_exchanges" do
        expect(serializer.editable_variants_for_incoming_exchanges.to_json).to include order_cycle.variants.first.id.to_s
        expect(serializer.editable_variants_for_incoming_exchanges.to_json).to_not include order_cycle.distributors.first.id.to_s
      end

      it "serializes the order cycle with editable_variants_for_outgoing_exchanges" do
        expect(serializer.editable_variants_for_outgoing_exchanges.to_json).to include order_cycle.variants.first.id.to_s
      end
    end
  end
end
