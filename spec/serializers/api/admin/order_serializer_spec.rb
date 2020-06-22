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
end
