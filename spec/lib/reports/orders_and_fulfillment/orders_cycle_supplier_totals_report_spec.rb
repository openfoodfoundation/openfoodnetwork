# frozen_string_literal: true

require 'spec_helper'

module Reporting
  module Reports
    module OrdersAndFulfillment
      describe OrderCycleSupplierTotals do
        let!(:distributor) { create(:distributor_enterprise) }

        let!(:order) do
          create(:completed_order_with_totals, line_items_count: 1, distributor: distributor)
        end
        let!(:supplier) do
          order.line_items.first.variant.product.supplier
        end
        let(:current_user) { distributor.owner }
        let(:params) { { display_summary_row: false } }
        let(:report) do
          OrderCycleSupplierTotals.new(current_user, params)
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
        context "with a VAT/GST-free supplier" do
          before(:each) do
            supplier.update(charges_sales_tax: false)
          end

          it "has a variant row when product belongs to a tax category" do
            product_tax_category_name = order.line_items.first.variant.product.tax_category.name

            supplier_name_field = report_table.first[0]
            supplier_vat_status_field = report_table.first[-2]
            product_tax_category_field = report_table.first[-1]

            expect(supplier_name_field).to eq supplier.name
            expect(supplier_vat_status_field).to eq "No"
            expect(product_tax_category_field).to eq product_tax_category_name
          end

          it "has a variant row when product doesn't belong to a tax category" do
            order.line_items.first.variant.product.update(tax_category_id: nil)
            supplier_name_field = report_table.first[0]
            supplier_vat_status_field = report_table.first[-2]
            product_tax_category_field = report_table.first[-1]

            expect(supplier_name_field).to eq supplier.name
            expect(supplier_vat_status_field).to eq "No"
            expect(product_tax_category_field).to eq "none"
          end
        end
        context "with a VAT/GST-enabled supplier" do
          before(:each) do
            supplier.update(charges_sales_tax: true)
          end

          it "has a variant row when product belongs to a tax category" do
            product_tax_category_name = order.line_items.first.variant.product.tax_category.name

            supplier_name_field = report_table.first[0]
            supplier_vat_status_field = report_table.first[-2]
            product_tax_category_field = report_table.first[-1]

            expect(supplier_name_field).to eq supplier.name
            expect(supplier_vat_status_field).to eq "Yes"
            expect(product_tax_category_field).to eq product_tax_category_name
          end

          it "has a variant row when product doesn't belong to a tax category" do
            order.line_items.first.variant.product.update(tax_category_id: nil)
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
    end
  end
end
