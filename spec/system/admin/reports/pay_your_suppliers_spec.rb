# frozen_string_literal: true

require "system_helper"

RSpec.describe "Pay Your Suppliers Report" do
  include ReportsHelper

  let(:hub) { create(:distributor_enterprise) }
  let(:order_cycle) { create(:open_order_cycle, distributors: [hub]) }
  let(:product) { order.products.first }
  let(:variant) { product.variants.first }
  let(:supplier) { variant.supplier }
  let(:current_user) { hub.owner }
  let!(:order) do
    create(:completed_order_with_totals, distributor: hub, order_cycle:, line_items_count: 1)
  end
  let(:params) { { display_summary_row: true } }
  let(:report) { Reporting::Reports::Suppliers::Base.new(current_user, { q: params }) }
  let(:report_table_rows) { report.rows }

  before do
    login_as current_user
    visit admin_reports_path
  end

  context "on Reports page" do
    it "should generate 'Pay Your Suppliers' report" do
      click_on 'Pay your suppliers'
      expect(page).to have_button("Go")
      run_report

      expect(page.find("table.report__table thead tr").text).to have_content([
        "Producer",
        "Producer Address",
        "Producer ABN/ACN",
        "Email",
        "Hub",
        "Hub Address",
        "Hub Contact Email",
        "Order number",
        "Order date",
        "Order Cycle",
        "OC Start Date",
        "OC End Date",
        "Product",
        "Variant Unit Name",
        "Quantity",
        "Total excl. fees and tax ($)",
        "Total excl. tax ($)",
        "Total fees excl. tax ($)",
        "Total tax on fees ($)",
        "Total Tax ($)",
        "Total ($)"
      ].join(" "))

      line = page.find('table.report__table tbody tr').text
      expect(line).to have_content([
        supplier.name,
        supplier.address.full_address,
        "none",
        "none",
        hub.name,
        hub.address.full_address,
        "none",
        order.number,
        order.completed_at.strftime("%d/%m/%Y"),
        order_cycle.name,
        order_cycle.orders_open_at.strftime("%d/%m/%Y"),
        order_cycle.orders_close_at.strftime("%d/%m/%Y"),
        product.name,
        variant.full_name,
        '1',
        '10.0',
        '10.0',
        '0.0',
        '0.0',
        '0.0',
        '10.0',
      ].compact.join(" "))
    end
  end
end
