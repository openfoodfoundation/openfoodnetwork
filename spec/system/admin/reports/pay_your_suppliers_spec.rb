# frozen_string_literal: true

require "system_helper"

RSpec.describe "Pay Your Suppliers Report" do
  include ReportsHelper

  let(:owner) { create(:user) }
  let(:hub1) { create(:enterprise, owner:) }
  let(:order_cycle1) { create(:open_order_cycle, distributors: [hub1]) }
  let!(:order1) do
    create(
      :completed_order_with_totals,
      distributor: hub1,
      order_cycle: order_cycle1,
      line_items_count: 2
    )
  end

  let(:hub2) { create(:enterprise, owner:) }
  let(:product2) { order1.products.first }
  let(:variant2) { product2.variants.first }
  let(:supplier2) { variant2.supplier }
  let(:order_cycle2) { create(:open_order_cycle, distributors: [hub2]) }
  let!(:order2) do
    create(
      :completed_order_with_totals,
      distributor: hub2,
      order_cycle: order_cycle2,
      line_items_count: 3
    )
  end

  before do
    login_as owner
    visit admin_reports_path

    update_line_items_product_names
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

      lines = page.all('table.report__table tbody tr').map(&:text)
      # 5 line_item rows + 1 summary row = 6 rows
      expect(lines.count).to be(6)

      hub1_rows = lines.select { |line| line.include?(hub1.name) }
      order1.line_items.each_with_index do |line_item, index|
        variant = line_item.variant
        supplier = line_item.supplier
        product = line_item.variant.product
        line = hub1_rows[index]

        expect(line).to have_content([
          supplier.name,
          supplier.address.full_address,
          "none",
          "none",
          hub1.name,
          hub1.address.full_address,
          "none",
          order1.number,
          order1.completed_at.to_date.to_s,
          order_cycle1.name,
          order_cycle1.orders_open_at.to_date.to_s,
          order_cycle1.orders_close_at.to_date.to_s,
          product.name,
          variant.full_name,
          1,
          10.0,
          10.0,
          0.0,
          0.0,
          0.0,
          10.0,
        ].compact.join(" "))
      end

      hub2_rows = lines.select { |line| line.include?(hub2.name) }
      order2.line_items.each_with_index do |line_item, index|
        variant = line_item.variant
        supplier = line_item.supplier
        product = line_item.variant.product
        line = hub2_rows[index]

        expect(line).to have_content([
          supplier.name,
          supplier.address.full_address,
          "none",
          "none",
          hub2.name,
          hub2.address.full_address,
          "none",
          order2.number,
          order2.completed_at.to_date.to_s,
          order_cycle2.name,
          order_cycle2.orders_open_at.to_date.to_s,
          order_cycle2.orders_close_at.to_date.to_s,
          product.name,
          variant.full_name,
          1,
          10.0,
          10.0,
          0.0,
          0.0,
          0.0,
          10.0,
        ].compact.join(" "))
      end

      # summary row
      expect(lines.last).to have_content("TOTAL 50.0 50.0 0.0 0.0 0.0 50.0")
    end
  end

  def update_line_items_product_names
    n = 1
    update_product_name_proc = proc do |order|
      order.line_items.each do |line_item|
        product = line_item.variant.product
        product.update!(name: "Product##{n}")
        n += 1
      end
    end

    update_product_name_proc.call(order1)
    update_product_name_proc.call(order2)
  end
end
