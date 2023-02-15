# frozen_string_literal: true

require "spec_helper"

describe Reporting::Reports::EnterpriseFeeSummary::Summarizer do
  let(:row) {
    {
      "total_amount" => 1, "payment_method_name" => nil,
      "shipping_method_name" => nil, "hub_name" => "Kimchi Hub",
      "enterprise_name" => nil, "fee_type" => nil,
      "customer_name" => "Fermented Greens",
      "customer_email" => "kimchi@example.com", "fee_name" => nil,
      "tax_category_name" => nil,
      "enterprise_fee_inherits_tax_category" => nil,
      "product_tax_category_name" => nil,
      "placement_enterprise_role" => nil,
      "adjustment_adjustable_type" => nil,
      "adjustment_source_distributor_name" => nil,
      "incoming_exchange_enterprise_name" => nil,
      "outgoing_exchange_enterprise_name" => nil,
      "id" => nil
    }
  }

  it "represents a transaction fee" do
    data = row.merge(
      "payment_method_name" => "cash",
      "adjustment_adjustable_type" => "Spree::Payment",
    )
    summarizer = described_class.new(data)
    expect(summarizer.fee_type).to eq "Payment Transaction"
  end

  it "represents an enterprise fee without name" do
    data = row.merge(
      "fee_name" => nil,
      "placement_enterprise_role" => "coordinator",
      "adjustment_adjustable_type" => "Spree::LineItem",
    )
    summarizer = described_class.new(data)
    expect(summarizer.fee_type).to eq nil
  end
end
