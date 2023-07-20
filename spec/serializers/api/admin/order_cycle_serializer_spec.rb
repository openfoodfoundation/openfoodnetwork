# frozen_string_literal: true

require "spec_helper"

describe Api::Admin::OrderCycleSerializer do
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
    distributor_ids = from_json(serializer.editable_variants_for_incoming_exchanges).keys
    variant_ids = from_json(serializer.editable_variants_for_incoming_exchanges).values.flatten

    expect(variant_ids).to include order_cycle.variants.first.id
    expect(distributor_ids).to_not include order_cycle.distributors.first.id.to_s
  end

  it "serializes the order cycle with editable_variants_for_outgoing_exchanges" do
    expect(serializer.editable_variants_for_outgoing_exchanges.to_json)
      .to include order_cycle.variants.first.id.to_s
  end

  def from_json(serializer_result)
    JSON.parse(serializer_result.to_json)
  end
end
