# frozen_string_literal: true

require "spec_helper"

describe Api::Admin::OrderSerializer do
  let(:serializer) { described_class.new order }

  describe "#display_outstanding_balance" do
    let(:order) { build(:order) }

    context 'when the balance is zero' do
      before { allow(order).to receive(:outstanding_balance) { 0 } }

      it 'returns empty string' do
        expect(serializer.display_outstanding_balance).to eq('')
      end
    end

    context 'when the balance is not zero' do
      before { allow(order).to receive(:outstanding_balance) { 10 } }

      it 'returns the balance' do
        expect(serializer.display_outstanding_balance).to eql('$10.00')
      end
    end
  end

  describe '#ready_to_capture' do
    let(:order) { create(:order) }

    before do
      allow(order).to receive(:payment_required?) { true }
    end

    context "there is a pending payment requiring authorization" do
      let!(:pending_payment) do
        create(
          :payment,
          order: order,
          state: 'pending',
          amount: 123.45,
          cvv_response_message: "https://stripe.com/redirect"
        )
      end

      it "returns false" do
        expect(serializer.ready_to_capture).to be false
      end
    end

    context "there is a pending payment but it does not require authorization" do
      let!(:pending_payment) do
        create(
          :payment,
          order: order,
          state: 'pending',
          amount: 123.45,
        )
      end

      it "returns true" do
        expect(serializer.ready_to_capture).to be true
      end
    end
  end
end
