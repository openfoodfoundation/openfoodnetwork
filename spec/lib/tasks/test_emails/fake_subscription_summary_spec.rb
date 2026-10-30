# frozen_string_literal: true

require "spec_helper"
require Rails.root.join("lib/tasks/test_emails/fake_subscription_summary")

RSpec.describe FakeSubscriptionSummary do
  let(:order) { double("Order", id: 42) }
  let(:orders) { [order] }

  subject(:summary) do
    described_class.new(shop_id: 7, type: :confirmation, orders: orders)
  end

  it "exposes the shop ID and summary type" do
    expect(summary.shop_id).to eq(7)
    expect(summary.type).to eq(:confirmation)
  end

  it "calculates order, issue, and success counts" do
    expect(summary.order_count).to eq(1)
    expect(summary.issue_count).to eq(1)
    expect(summary.success_count).to eq(0)
  end

  it "reports a payment issue for the first order" do
    expect(summary.issues).to eq(payment: { 42 => "Payment failed" })
  end

  it "returns orders affected by an issue" do
    expect(summary.orders_affected_by(:payment)).to eq(orders)
  end

  it "returns empty unrecorded IDs and subscription issues" do
    expect(summary.unrecorded_ids).to eq([])
    expect(summary.subscription_issues).to eq([])
  end

  context "when there are multiple orders" do
    let(:second_order) { double("Order", id: 43) }
    let(:orders) { [order, second_order] }

    it "counts all orders while reporting the first order as the payment issue" do
      expect(summary.order_count).to eq(2)
      expect(summary.success_count).to eq(1)
      expect(summary.issues).to eq(payment: { 42 => "Payment failed" })
    end
  end
end
