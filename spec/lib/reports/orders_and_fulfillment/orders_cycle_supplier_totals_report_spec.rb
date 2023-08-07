# frozen_string_literal: true

require 'spec_helper'

describe Reporting::Reports::OrdersAndFulfillment::OrderCycleSupplierTotals do
  let!(:distributor) { create(:distributor_enterprise) }

  let!(:order) do
    create(:completed_order_with_totals, line_items_count: 1, distributor: distributor)
  end
  let!(:supplier) do
    order.line_items.first.variant.product.supplier
  end
  let(:current_user) { distributor.owner }
  let(:params) { { display_summary_row: false, fields_to_hide: [] } }
  let(:report) do
    described_class.new(current_user, params)
  end

  let(:table_headers) do
    report.table_headers
  end

  let(:report_table) do
    report.table_rows
  end

  it "generates the report" do
    expect(report_table.length).to eq(1)
  end

  describe "total_units column" do
    let(:item) { order.line_items.first }
    let(:variant) { item.variant }

    it "contains a sum of total items" do
      variant.product.update!(variant_unit: "items", variant_unit_name: "bottle")
      variant.update!(unit_value: 6) # six-pack
      item.update!(final_weight_volume: nil) # reset unit information
      item.update!(quantity: 3)

      expect(table_headers[4]).to eq "Total Units"
      expect(report_table[0][4]).to eq 18 # = 3 * 6, three six-packs
    end

    it "contains a sum of total weight" do
      variant.product.update!(variant_unit: "weight")
      variant.update!(unit_value: 200) # grams
      item.update!(final_weight_volume: nil) # reset unit information
      item.update!(quantity: 3)

      expect(table_headers[4]).to eq "Total Units"
      expect(report_table[0][4]).to eq 0.6 # kg (= 3 * 0.2kg)
    end

    it "is blank when line items miss a unit" do
      # This is not possible with the current code but was possible years ago.
      # So I'm using `update_columns` to save invalid data.
      # We still have lots of that data in our databases though.
      variant.product.update(variant_unit: "items", variant_unit_name: "container")
      variant.update_columns(unit_value: nil, unit_description: "vacuum")
      item.update!(final_weight_volume: nil) # reset unit information

      expect(table_headers[4]).to eq "Total Units"
      expect(report_table[0][4]).to eq " "
    end

    it "is summarised" do
      expect(report).to receive(:display_summary_row?).and_return(true)

      variant.product.update!(variant_unit: "weight")
      variant.update!(unit_value: 200) # grams
      item.update!(final_weight_volume: nil) # reset unit information
      item.update!(quantity: 3)

      # And a second item to add up with:
      item2 = create(:line_item, order: order)

      expect(table_headers[4]).to eq "Total Units"
      expect(report_table[0][4]).to eq 0.6 # kg (= 3 * 0.2kg)
      expect(report_table[1][4]).to eq 0.001 # 1 gram default value
      expect(report_table[2][4]).to eq 0.601 # summary
    end

    it "is blank in summary when one line item misses a unit and another not" do
      expect(report).to receive(:display_summary_row?).and_return(true)

      # This is not possible with the current code but was possible years ago.
      # So I'm using `update_columns` to save invalid data.
      # We still have lots of that data in our databases though.
      variant.product.update(variant_unit: "items", variant_unit_name: "container")
      variant.update_columns(unit_value: nil, unit_description: "vacuum")
      item.update!(final_weight_volume: nil) # reset unit information

      # This second line item will have a default a bigint value.
      order.line_items << create(:line_item)

      # Create deterministic / aphabetical order of items:
      order.line_items[0].variant.product.update!(name: "Apple")
      order.line_items[1].variant.product.update!(name: "Banana")

      # Generating the report used to raise:
      # > TypeError: no implicit conversion of BigDecimal into String
      expect(table_headers[4]).to eq "Total Units"
      expect(report_table[0][4]).to eq " "
      expect(report_table[1][4]).to eq 0.001 # 1 gram default value
      expect(report_table[2][4]).to eq " " # summary
    end
  end

  context "with a VAT/GST-free supplier" do
    let(:tax_category) { create(:tax_category) }

    before do
      supplier.update(charges_sales_tax: false)
      order.line_items.first.variant.update(tax_category_id: tax_category.id)
    end

    it "has a variant row when product belongs to a tax category" do
      product_tax_category_name = order.line_items.first.variant.tax_category.name

      supplier_name_field = report_table.first[0]
      supplier_vat_status_field = report_table.first[-2]
      product_tax_category_field = report_table.first[-1]

      expect(supplier_name_field).to eq supplier.name
      expect(supplier_vat_status_field).to eq "No"
      expect(product_tax_category_field).to eq product_tax_category_name
    end

    it "has a variant row when product doesn't belong to a tax category" do
      order.line_items.first.variant.update(tax_category_id: nil)

      supplier_name_field = report_table.first[0]
      supplier_vat_status_field = report_table.first[-2]
      product_tax_category_field = report_table.first[-1]

      expect(supplier_name_field).to eq supplier.name
      expect(supplier_vat_status_field).to eq "No"
      expect(product_tax_category_field).to eq "none"
    end
  end

  context "with a VAT/GST-enabled supplier" do
    let(:tax_category) { create(:tax_category) }

    before(:each) do
      supplier.update(charges_sales_tax: true)
      order.line_items.first.variant.update(tax_category_id: tax_category.id)
    end

    it "has a variant row when product belongs to a tax category" do
      product_tax_category_name = order.line_items.first.variant.tax_category.name

      supplier_name_field = report_table.first[0]
      supplier_vat_status_field = report_table.first[-2]
      product_tax_category_field = report_table.first[-1]

      expect(supplier_name_field).to eq supplier.name
      expect(supplier_vat_status_field).to eq "Yes"
      expect(product_tax_category_field).to eq product_tax_category_name
    end

    it "has a variant row when product doesn't belong to a tax category" do
      order.line_items.first.variant.update(tax_category_id: nil)

      supplier_name_field = report_table.first[0]
      supplier_vat_status_field = report_table.first[-2]
      product_tax_category_field = report_table.first[-1]

      expect(supplier_name_field).to eq supplier.name
      expect(supplier_vat_status_field).to eq "Yes"
      expect(product_tax_category_field).to eq "none"
    end
  end

  it "includes sku column" do
    variant_sku = order.line_items.first.variant.sku
    last_column_title = table_headers[-3]
    first_row_last_column_value = report_table.first[-3]

    expect(last_column_title).to eq "SKU"
    expect(first_row_last_column_value).to eq variant_sku
  end
end
