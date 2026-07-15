# frozen_string_literal: true

module Reporting
  module Reports
    module OrdersAndFulfillment
      RSpec.describe OrderCycleDistributorTotalsBySupplier do
        let!(:distributor) { create(:distributor_enterprise) }

        let!(:order) do
          create(:completed_order_with_totals, line_items_count: 1, distributor:)
        end

        let(:current_user) { distributor.owner }
        let(:params) { { display_summary_row: true } }
        let(:report) do
          OrderCycleDistributorTotalsBySupplier.new(current_user, params)
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

          supplier = order.line_items.first.supplier
          supplier_name_field = report_table.first[1]
          expect(supplier_name_field).to eq supplier.name
        end

        context "with same product ordered via different shipping methods" do
          let!(:order) { nil }
          let(:supplier) { create(:supplier_enterprise) }
          let(:product) {
            create(:simple_product, enterprise_id: supplier.id, on_demand: true)
          }
          let(:variant) { product.variants.first }
          let!(:pickup) {
            create(:shipping_method, name: "Pickup", distributors: [distributor])
          }
          let!(:delivery) {
            create(:shipping_method, name: "Delivery", distributors: [distributor])
          }

          let!(:order1) do
            create(:order, distributor:, state: 'complete',
                           completed_at: Time.zone.now).tap do |o|
              create(:line_item_with_shipment, variant:, quantity: 3, order: o,
                                               shipping_method: pickup)
            end
          end

          let!(:order2) do
            create(:order, distributor:, state: 'complete',
                           completed_at: Time.zone.now).tap do |o|
              create(:line_item_with_shipment, variant:, quantity: 4, order: o,
                                               shipping_method: delivery)
            end
          end

          it "separates rows by shipping method with correct quantities and totals" do
            expect(report_table.length).to eq(3)

            shipping_methods = report.rows.map(&:shipping_method).compact_blank
            expect(shipping_methods).to contain_exactly("Pickup", "Delivery")

            pickup_row = report.rows.find { |r| r.shipping_method == "Pickup" }
            delivery_row = report.rows.find { |r| r.shipping_method == "Delivery" }
            expect(pickup_row.quantity).to eq(3)
            expect(delivery_row.quantity).to eq(4)

            summary_row = report_table.last
            expect(summary_row[6]).to be_within(0.01).of(70.00)
          end
        end
      end
    end
  end
end
