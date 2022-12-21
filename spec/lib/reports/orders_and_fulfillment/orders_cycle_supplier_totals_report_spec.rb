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

        let(:current_user) { distributor.owner }
        let(:params) { { display_summary_row: false, fields_to_hide: [] } }
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

        it "has a variant row" do
          supplier = order.line_items.first.variant.product.supplier
          supplier_name_field = report_table.first[0]
          expect(supplier_name_field).to eq supplier.name
        end

        it "includes sku column" do
          variant_sku = order.line_items.first.variant.sku
          last_column_title = table_headers.last
          first_row_last_column_value = report_table.first.last

          expect(last_column_title).to eq "SKU"
          expect(first_row_last_column_value).to eq variant_sku
        end
      end
    end
  end
end
