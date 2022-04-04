# frozen_string_literal: true

require 'spec_helper'
require 'open_food_network/orders_and_fulfillment_report/supplier_totals_by_distributor_report'

RSpec.describe OpenFoodNetwork::OrdersAndFulfillmentReport::SupplierTotalsByDistributorReport do
  let!(:distributor) { create(:distributor_enterprise) }

  let!(:order) do
    create(:completed_order_with_totals, line_items_count: 1, distributor: distributor)
  end

  let(:current_user) { distributor.owner }

  let(:report) do
    report_options = { report_subtype: described_class::REPORT_TYPE }
    OpenFoodNetwork::OrdersAndFulfillmentReport.new(current_user, report_options, true)
  end

  let(:report_table) do
    report.table_rows
  end

  it "generates the report" do
    expect(report_table.length).to eq(2)
  end

  it "has a variant row under the distributor" do
    supplier = order.line_items.first.variant.product.supplier
    supplier_name_field = report_table.first[0]
    expect(supplier_name_field).to eq supplier.name

    distributor_name_field = report_table.first[3]
    expect(distributor_name_field).to eq distributor.name

    total_field = report_table.last[3]
    expect(total_field).to eq I18n.t("admin.reports.total")
  end
end
