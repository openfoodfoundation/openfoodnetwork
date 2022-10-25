# frozen_string_literal: true

require 'spec_helper'

module Reporting
  module Reports
    module OrdersAndFulfillment
      describe OrderCycleSupplierTotalsByDistributor do
        let!(:distributor) { create(:distributor_enterprise) }

        let!(:order) do
          create(:completed_order_with_totals, line_items_count: 3, distributor: distributor)
        end

        let(:current_user) { distributor.owner }
        let(:params) { { display_summary_row: true } }
        let(:report) do
          OrderCycleSupplierTotalsByDistributor.new(current_user, params)
        end

        let(:report_table) do
          report.table_rows
        end

        it "generates the report" do
          expect(report_table.length).to eq(6)
        end

        it "has a variant row under the distributor" do
          supplier = order.line_items.first.variant.product.supplier
          expect(report.rows.first.producer).to eq supplier.name
          expect(report.rows.first.hub).to eq distributor.name
        end

        it "lists products sorted by name" do
          order.line_items[0].variant.product.update(name: "Cucumber")
          order.line_items[1].variant.product.update(name: "Apple")
          order.line_items[2].variant.product.update(name: "Banane")
          product_names = report.rows.map(&:product).filter(&:present?)
          expect(product_names).to eq(["Apple", "Banane", "Cucumber"])
        end
      end
    end
  end
end
