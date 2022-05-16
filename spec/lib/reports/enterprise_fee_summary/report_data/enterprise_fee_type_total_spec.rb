# frozen_string_literal: true

require "spec_helper"

describe Reporting::Reports::EnterpriseFeeSummary::ReportData::EnterpriseFeeTypeTotal do
  it "sorts instances according to their attributes" do
    instance_a = described_class.new(
      fee_type: "sales",
      enterprise_name: "Enterprise A",
      fee_name: "A Sales",
      customer_name: "Customer A",
      fee_placement: "Incoming",
      fee_calculated_on_transfer_through_name: "Transfer Enterprise B",
      tax_category_name: "Sales 4%",
      total_amount: "12.00"
    )

    instance_b = described_class.new(
      fee_type: "sales",
      enterprise_name: "Enterprise A",
      fee_name: "B Sales",
      customer_name: "Customer A",
      fee_placement: "Incoming",
      fee_calculated_on_transfer_through_name: "Transfer Enterprise B",
      tax_category_name: "Sales 4%",
      total_amount: "12.00"
    )

    instance_c = described_class.new(
      fee_type: "admin",
      enterprise_name: "Enterprise A",
      fee_name: "C Admin",
      customer_name: "Customer B",
      fee_placement: "Incoming",
      fee_calculated_on_transfer_through_name: nil,
      tax_category_name: "Sales 6%",
      total_amount: "12.00"
    )

    list = [
      instance_a,
      instance_b,
      instance_c
    ]

    expect(list.sort).to eq([instance_c, instance_a, instance_b])
  end
end
