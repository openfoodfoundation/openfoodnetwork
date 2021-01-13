# frozen_string_literal: true

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

  describe '#outstanding_balance' do
    context 'when the customer_balance feature is enabled' do
      before do
        allow(OpenFoodNetwork::FeatureToggle)
          .to receive(:enabled?).with(:customer_balance, order.user) { true }

        allow(order).to receive(:balance_value).and_return(-1.23)
      end

      it "returns the object's balance_value from the users perspective" do
        expect(serializer.serializable_hash[:outstanding_balance]).to eq(1.23)
      end
    end

    context 'when the customer_balance is not enabled' do
      before do
        allow(OpenFoodNetwork::FeatureToggle)
          .to receive(:enabled?).with(:customer_balance, order.user) { false }
      end

      it 'calls #outstanding_balance on the object' do
        expect(serializer.serializable_hash[:outstanding_balance]).to eq(1.0)
      end
    end
  end
end
