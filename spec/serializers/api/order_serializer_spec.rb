# frozen_string_literal: true

RSpec.describe Api::OrderSerializer do
  let(:serializer) { Api::OrderSerializer.new order }
  let(:order) { create(:completed_order_with_totals) }

  before do
    allow(order).to receive(:balance_value).and_return(-1.23)
  end

  describe '#serializable_hash' do
    let!(:completed_payment) do
      create(:payment, :completed, order:, amount: order.total - 1)
    end
    let!(:payment) { create(:payment, order:, state: 'checkout', amount: 123.45) }

    it "serializes an order" do
      expect(serializer.serializable_hash[:number]).to eq(order.number)
    end

    it "convert the state attributes to translatable keys" do
      hash = serializer.serializable_hash

      expect(hash[:state]).to eq("complete")
      expect(hash[:payment_state]).to eq("balance_due")
    end

    it "only serializes completed payments" do
      hash = serializer.serializable_hash

      expect(hash[:payments].first[:amount]).to eq(completed_payment.amount)
    end
  end

  describe '#outstanding_balance' do
    it "returns the object's balance_value from the users perspective" do
      expect(serializer.serializable_hash[:outstanding_balance]).to eq(1.23)
    end
  end

  describe '#paid' do
    it "returns false when payment_state is balance_due" do
      allow(order).to receive(:payment_state).and_return('balance_due')

      expect(serializer.serializable_hash[:paid]).to eq(false)
    end

    it "returns true when payment_state is paid" do
      allow(order).to receive(:payment_state).and_return('paid')

      expect(serializer.serializable_hash[:paid]).to eq(true)
    end

    it "returns true when payment_state is credit_owed" do
      allow(order).to receive(:payment_state).and_return('credit_owed')

      expect(serializer.serializable_hash[:paid]).to eq(true)
    end
  end
end
