# frozen_string_literal: true

require 'spec_helper'

module Reporting
  module Reports
    module OrdersAndFulfillment
      describe DistributorTotalsBySupplierReport do
        let!(:distributor) { create(:distributor_enterprise) }

        let!(:order) do
          create(:completed_order_with_totals, line_items_count: 1, distributor: distributor)
        end

        let(:current_user) { distributor.owner }

        let(:report) do
          report_options = { report_subtype: described_class::REPORT_TYPE }
          OrdersAndFulfillmentReport.new(current_user, report_options)
        end

        let(:report_table) do
          report.table_rows
        end

        it "generates the report" do
          expect(report_table.length).to eq(2)
        end

        it "has a variant row under the distributor" do
          distributor_name_field = report_table.first[0]
          expect(distributor_name_field).to eq distributor.name

          supplier = order.line_items.first.variant.product.supplier
          supplier_name_field = report_table.first[1]
          expect(supplier_name_field).to eq supplier.name

          total_field = report_table.last[1]
          expect(total_field).to eq I18n.t("admin.reports.total")
        end
      end
    end
  end
end
