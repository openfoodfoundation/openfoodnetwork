require 'spec_helper'

describe Api::OrderSerializer do
  let(:serializer) { Api::OrderSerializer.new order }
  let(:order) { create(:completed_order_with_totals) }


  it "serializes an order" do
    expect(serializer.to_json).to match order.number.to_s
  end

  it "convert the state attributes to translatable keys" do
    expect(serializer.to_json).to match "complete"
    expect(serializer.to_json).to match "balance_due"
  end

end
