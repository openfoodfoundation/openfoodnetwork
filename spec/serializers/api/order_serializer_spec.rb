require 'spec_helper'

describe Api::OrderSerializer do
  let(:serializer) { Api::OrderSerializer.new order }
  let(:order) { create(:completed_order_with_totals) }

  let!(:completed_payment) { create(:payment, order: order, state: 'completed', amount: order.total - 1) }
  let!(:payment) { create(:payment, order: order, state: 'checkout', amount: 123.45) }

  it "serializes an order" do
    expect(serializer.to_json).to match order.number.to_s
  end

  it "convert the state attributes to translatable keys" do
    # byebug if serializer.to_json =~ /balance_due/
    expect(serializer.to_json).to match "complete"
    expect(serializer.to_json).to match "balance_due"
  end

  it "only serializes completed payments" do
    expect(serializer.to_json).to match completed_payment.amount.to_s
    expect(serializer.to_json).to_not match payment.amount.to_s
  end
end
