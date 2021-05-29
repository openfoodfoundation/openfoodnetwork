# frozen_string_literal: true

require "spec_helper"

describe Api::Admin::OrderSerializer do
  let(:serializer) { described_class.new order }
  let(:order) { build(:order) }

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

    context "there is a payment requiring authorization" do
      let!(:payment) do
        create(
          :payment,
          order: order,
          state: 'requires_authorization',
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

  describe "#completed_at" do
    let(:order) { build(:order, state: 'complete', completed_at: DateTime.parse("2021-04-02")) }

    it "formats the date" do
      expect(serializer.completed_at).to eq("April 02, 2021")
    end
  end

  describe "#distributor" do
    before { order.distributor = build(:distributor_enterprise) }

    it "returns distributor object with id key" do
      expect(serializer.distributor.id).to eq(order.distributor.id)
    end
  end

  describe "#number" do
    it "returns the order number" do
      expect(serializer.number).to eq(order.number)
    end
  end
end
