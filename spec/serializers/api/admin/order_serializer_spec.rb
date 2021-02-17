# frozen_string_literal: true

require "spec_helper"

describe Api::Admin::OrderSerializer do
  let(:serializer) { described_class.new order }

  describe "#display_outstanding_balance" do
    let(:order) { create(:order) }

    it "returns empty string" do
      expect(serializer.display_outstanding_balance).to eql("")
    end

    context "with outstanding payments" do
      let(:order) { create(:order_without_full_payment, unpaid_amount: 10) }

      it "generates the outstanding balance" do
        expect(serializer.display_outstanding_balance).to eql("$10.00")
      end
    end

    context "with credit owed" do
      let(:order) { create(:order_with_credit_payment, credit_amount: 20) }

      it "generates the outstanding balance" do
        expect(serializer.display_outstanding_balance).to eql("$-20.00")
      end
    end
  end

  describe '#ready_to_capture' do
    let(:order) { create(:order) }

    before do
      allow(order).to receive(:payment_required?) { true }
    end

    context "there is a payment pending authorization" do
      let!(:pending_payment) {
        create(
          :payment,
          order: order,
          state: 'pending',
          amount: 123.45,
          cvv_response_message: "https://stripe.com/redirect"
        )
      }

      it "returns false if there is a payment requiring authorization" do
        expect(serializer.ready_to_capture).to be false
      end
    end

    context "there is a pending payment but it does not require authorization" do
      let!(:pending_payment) {
        create(
          :payment,
          order: order,
          state: 'pending',
          amount: 123.45,
        )
      }

      it "returns true if there is no payment requiring authorization" do
        expect(serializer.ready_to_capture).to be true
      end
    end
  end
end
