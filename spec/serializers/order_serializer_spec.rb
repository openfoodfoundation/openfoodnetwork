#require 'spec_helper'

describe Api::OrderSerializer do
  let(:serializer) { Api::OrderSerializer.new order }
  let(:order) { create(:completed_order_with_totals) }


  it "serializes an order" do
    expect(serializer.to_json).to match order.number.to_s
  end

  it "converts the total to currency and amount" do
    expect(serializer.serializable_hash[:total_money].keys).to include :currency_symbol
    # Not sure what currency symbol is in test env
    expect(serializer.serializable_hash[:total_money].keys).to include :amount
    expect(serializer.serializable_hash[:total_money][:amount]).to eq "0.00"
  end

  it "converts the balance to currency and amount" do
    expect(serializer.serializable_hash[:balance_money].keys).to include :currency_symbol
    # Not sure what currency symbol is in test env
    expect(serializer.serializable_hash[:balance_money].keys).to include :amount
    expect(serializer.serializable_hash[:balance_money][:amount]).to eq "0.00"
  end
  it "convert the state attributes to readable strings" do
    expect(serializer.to_json).to match "Complete"
    expect(serializer.to_json).to match "Balance due"
  end

end
