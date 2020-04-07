require "spec_helper"
require 'open_food_network/orders_and_fulfillments_report/customer_totals_report'

RSpec.describe OpenFoodNetwork::OrdersAndFulfillmentsReport::CustomerTotalsReport do
  let!(:distributor) { create(:distributor_enterprise) }
  let!(:customer) { create(:customer, enterprise: distributor) }
  let(:current_user) { distributor.owner }

  let(:report) do
    report_options = { report_type: described_class::REPORT_TYPE }
    OpenFoodNetwork::OrdersAndFulfillmentsReport.new(current_user, report_options, true)
  end

  let(:report_table) do
    OpenFoodNetwork::OrderGrouper.new(report.rules, report.columns).table(report.table_items)
  end

  context "viewing the report" do
    let!(:order) do
      create(:completed_order_with_totals, line_items_count: 1, user: customer.user,
             customer: customer, distributor: distributor)
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

  context "loading shipping methods" do
    let!(:shipping_method1) {
      create(:shipping_method, distributors: [distributor], name: "First")
    }
    let!(:shipping_method2) {
      create(:shipping_method, distributors: [distributor], name: "Second")
    }
    let!(:shipping_method3) {
      create(:shipping_method, distributors: [distributor], name: "Third")
    }
    let!(:order) do
      create(:completed_order_with_totals, line_items_count: 1, user: customer.user,
             customer: customer, distributor: distributor)
    end

    before do
      order.shipments.each(&:refresh_rates)
      order.select_shipping_method(shipping_method2.id)
    end

    it "displays the correct shipping_method" do
      shipping_method_name_field = report_table.first[15]
      expect(shipping_method_name_field).to eq shipping_method2.name
    end
  end

  context 'when a variant override applies' do
    let!(:order) do
      create(:completed_order_with_totals, line_items_count: 1, user: customer.user,
             customer: customer, distributor: distributor)
    end
    let(:overidden_sku) { 'magical_sku' }

    before do
      create(
        :variant_override,
        hub: distributor,
        variant: order.line_items.first.variant,
        sku: overidden_sku
      )
    end

    it 'uses the sku from the variant override' do
      sku_field = report_table.first[23]
      expect(sku_field).to eq overidden_sku
    end
  end
end
