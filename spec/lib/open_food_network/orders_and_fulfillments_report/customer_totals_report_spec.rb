require "spec_helper"

RSpec.describe OpenFoodNetwork::OrdersAndFulfillmentsReport::CustomerTotalsReport do
  let!(:distributor) { create(:distributor_enterprise) }

  let!(:customer) { create(:customer, enterprise: distributor) }

  let!(:order) do
    create(:completed_order_with_totals, line_items_count: 1, user: customer.user,
                                         customer: customer, distributor: distributor)
  end

  let(:current_user) { distributor.owner }
  let(:permissions) { OpenFoodNetwork::Permissions.new(current_user) }

  let(:report) do
    report_options = { report_type: described_class::REPORT_TYPE }
    OpenFoodNetwork::OrdersAndFulfillmentsReport.new(permissions, report_options, true)
  end

  let(:report_table) do
    OpenFoodNetwork::OrderGrouper.new(report.rules, report.columns).table(report.table_items)
  end

  it "generates the report" do
    expect(report_table.length).to eq(2)
  end

  it "has a line item row" do
    distributor_name_field = report_table.first[0]
    expect(distributor_name_field).to eq distributor.name

    customer_name_field = report_table.first[1]
    expect(customer_name_field).to eq order.bill_address.full_name

    total_field = report_table.last[5]
    expect(total_field).to eq I18n.t("admin.reports.total")
  end
end
