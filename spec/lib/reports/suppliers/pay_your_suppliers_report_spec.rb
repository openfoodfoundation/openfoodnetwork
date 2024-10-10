# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Pay Your Suppliers Report" do
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

  context "without fees and taxes" do
    it "Generates the report" do
      expect(report_table_rows.length).to eq(1)
      table_row = report_table_rows.first

      expect(table_row.producer).to eq(supplier.name)
      expect(table_row.producer_address).to eq(supplier.address.full_address)
      expect(table_row.producer_abn_acn).to eq("none")
      expect(table_row.email).to eq("none")
      expect(table_row.hub).to eq(hub.name)
      expect(table_row.hub_address).to eq(hub.address.full_address)
      expect(table_row.hub_contact_email).to eq("none")
      expect(table_row.order_number).to eq(order.number)
      expect(table_row.order_date).to eq(order.completed_at.to_date.to_s)
      expect(table_row.order_cycle).to eq(order_cycle.name)
      expect(table_row.order_cycle_start_date).to eq(
        order_cycle.orders_open_at.to_date.to_s
      )
      expect(table_row.order_cycle_end_date).to eq(order_cycle.orders_close_at.to_date.to_s)
      expect(table_row.product).to eq(product.name)
      expect(table_row.variant_unit_name).to eq(variant.full_name)
      expect(table_row.quantity).to eq(1)
      expect(table_row.total_excl_vat_and_fees.to_f).to eq(10.0)
      expect(table_row.total_excl_vat.to_f).to eq(10.0)
      expect(table_row.total_fees_excl_vat.to_f).to eq(0.0)
      expect(table_row.total_vat_on_fees.to_f).to eq(0.0)
      expect(table_row.total_tax.to_f).to eq(0.0)
      expect(table_row.total.to_f).to eq(10.0)
    end
  end

  context "with taxes and fees" do
    let(:line_item) { order.line_items.first }
    let!(:fees_adjustment) do
      create(:adjustment, originator_type: "EnterpriseFee", adjustable: line_item, amount: 0.1)
    end
    let!(:tax_adjustment) do
      create(:adjustment, originator_type: "Spree::TaxRate", adjustable: line_item, amount: 0.1)
    end

    it "Generates the report" do
      expect(report_table_rows.length).to eq(1)
      table_row = report_table_rows.first

      expect(table_row.total_excl_vat_and_fees.to_f).to eq(10.0)
      expect(table_row.total_excl_vat.to_f).to eq(10.1)
      expect(table_row.total_fees_excl_vat.to_f).to eq(0.1)
      expect(table_row.total_vat_on_fees.to_f).to eq(0.0)
      expect(table_row.total_tax.to_f).to eq(0.1)
      expect(table_row.total.to_f).to eq(10.2)
    end
  end
end
