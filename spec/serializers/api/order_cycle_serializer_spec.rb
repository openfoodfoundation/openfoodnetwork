# frozen_string_literal: true

require 'spec_helper'

describe Api::OrderCycleSerializer do
  let(:order_cycle) { create(:simple_order_cycle) }
  let(:serializer) { Api::OrderCycleSerializer.new(order_cycle).to_json }

  it "serializes the OC id as order_cycle_id" do
    expect(serializer).to match "order_cycle_id"
    expect(serializer).to match order_cycle.id.to_s
  end

  it "includes orders_close_at" do
    expect(serializer).to match "orders_close_at"
    expect(serializer).to match order_cycle.orders_close_at.to_date.to_s
  end
end
