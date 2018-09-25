require 'spec_helper'

describe PendingPayments do
  let(:order1) {
    create(:order_with_totals_and_distribution,
           completed_at: 1.day.ago, state: "complete",
           payments: [create(:payment, state: 'checkout')])
  }
  let(:order2) {
    create(:order_with_totals_and_distribution,
           completed_at: 1.day.ago, state: "complete",
           payments: [create(:payment, state: 'completed')])
  }

  describe "#can_be_captured?" do
    it "responds with a boolean; if an order has payments that can be captured or not" do
      expect(PendingPayments.new(order1).can_be_captured?).to be_truthy
      expect(PendingPayments.new(order2).can_be_captured?).to_not be_truthy
    end
  end

  describe "#payment_object" do
    it "returns a capturable payment object if there is one present" do
      expect(PendingPayments.new(order1).payment_object).to be_a Spree::Payment
      expect(PendingPayments.new(order2).payment_object).to be_nil
    end
  end
end
