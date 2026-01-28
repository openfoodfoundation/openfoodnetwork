# frozen_string_literal: true

module Reporting
  module Reports
    module OrdersAndFulfillment
      RSpec.describe OrderCycleSupplierTotalsByDistributor do
        let!(:distributor) { create(:distributor_enterprise) }
        let(:order_cycle) { create(:simple_order_cycle, distributors: [distributor]) }

        describe "as the distributor" do
          let!(:order) do
            create(:completed_order_with_totals, line_items_count: 3, distributor:)
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
            supplier = order.line_items.first.variant.supplier
            expect(report.rows.first.producer).to eq supplier.name
            expect(report.rows.first.hub).to eq distributor.name
          end

          it "lists products sorted by name" do
            order.line_items[0].update(product_name: "Cucumber")
            order.line_items[1].update(product_name: "Apple")
            order.line_items[2].update(product_name: "Banane")

            product_names = report.rows.map(&:product).compact_blank
            expect(product_names).to eq(["Apple", "Banane", "Cucumber"])
          end
        end

        describe "as the supplier permitting products in the order cycle" do
          let!(:order) {
            create(:completed_order_with_totals, line_items_count: 0, distributor:,
                                                 order_cycle_id: order_cycle.id)
          }
          let(:supplier){ order.line_items.first.variant.supplier }

          before do
            3.times do
              owner = create(:user)
              s = create(:supplier_enterprise, owner:)
              variant = create(:variant, supplier: s)
              create(:line_item_with_shipment, variant:, quantity: 1, order:)
            end

            create(:enterprise_relationship, parent: supplier, child: distributor,
                                             permissions_list: [:add_to_order_cycle])
          end

          let(:current_user) { supplier.owner }
          let(:params) { { display_summary_row: true } }
          let(:report) do
            OrderCycleSupplierTotalsByDistributor.new(current_user, params)
          end

          let(:report_table) do
            report.table_rows
          end

          it "generates the report" do
            expect(report_table.length).to eq(2)
          end

          it "has a variant row under the distributor" do
            expect(report.rows.first.producer).to eq supplier.name
            expect(report.rows.first.hub).to eq distributor.name
          end

          it "lists products sorted by name" do
            order.line_items[0].update(product_name: "Cucumber")
            order.line_items[1].update(product_name: "Apple")
            order.line_items[2].update(product_name: "Banane")
            product_names = report.rows.map(&:product).compact_blank
            # only the supplier's variant is displayed
            expect(product_names).to include("Cucumber")
            expect(product_names).not_to include("Apple", "Banane")
          end
        end
      end
    end
  end
end
