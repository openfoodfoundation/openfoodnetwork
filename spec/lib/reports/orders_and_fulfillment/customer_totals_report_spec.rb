# frozen_string_literal: true

require "spec_helper"

module Reporting
  module Reports
    module OrdersAndFulfillment
      describe CustomerTotalsReport do
        let!(:distributor) { create(:distributor_enterprise) }
        let!(:customer) { create(:customer, enterprise: distributor) }
        let(:current_user) { distributor.owner }

        let(:report) do
          report_options = { report_subtype: described_class::REPORT_TYPE }
          OrdersAndFulfillmentReport.new(current_user, report_options, true)
        end

        let(:report_table) do
          report.table_rows
        end

        context "viewing the report" do
          let!(:order) do
            create(:completed_order_with_totals, line_items_count: 1, user: customer.user,
                                                 customer: customer, distributor: distributor)
          end

          it "generates the report" do
            expect(report_table.length).to eq(2)
          end

          it "has a line item row" do
            distributor_name_field = report_table.first[0]
            expect(distributor_name_field).to eq distributor.name

            customer_name_field = report_table.first[1]
            expect(customer_name_field).to eq order.bill_address.full_name

            total_field = report_table.last[5]
            expect(total_field).to eq I18n.t("admin.reports.total")
          end

          it 'includes the order number and date in item rows' do
            order_number_and_date_fields = report_table.first[33..34]
            expect(order_number_and_date_fields).to eq([
                                                         order.number,
                                                         order.completed_at.strftime("%F %T"),
                                                       ])
          end

          it 'includes the order number and date in total rows' do
            order_number_and_date_fields = report_table.last[33..34]
            expect(order_number_and_date_fields).to eq([
                                                         order.number,
                                                         order.completed_at.strftime("%F %T"),
                                                       ])
          end
        end

        context "loading shipping methods" do
          let!(:shipping_method1) {
            create(:shipping_method, distributors: [distributor], name: "First")
          }
          let!(:shipping_method2) {
            create(:shipping_method, distributors: [distributor], name: "Second")
          }
          let!(:shipping_method3) {
            create(:shipping_method, distributors: [distributor], name: "Third")
          }
          let!(:order) do
            create(:completed_order_with_totals, line_items_count: 1, user: customer.user,
                                                 customer: customer, distributor: distributor)
          end

          before do
            order.shipments.each(&:refresh_rates)
            order.select_shipping_method(shipping_method2.id)
          end

          it "displays the correct shipping_method" do
            shipping_method_name_field = report_table.first[15]
            expect(shipping_method_name_field).to eq shipping_method2.name
          end
        end

        context "displaying payment fees" do
          context "with both failed and completed payments present" do
            let!(:order) {
              create(:order_ready_to_ship, user: customer.user,
                                           customer: customer, distributor: distributor)
            }
            let(:completed_payment) { order.payments.completed.first }
            let!(:failed_payment) { create(:payment, order: order, state: "failed") }

            before do
              completed_payment.adjustment.update amount: 123.00
              failed_payment.adjustment.update amount: 456.00, eligible: false, state: "finalized"
            end

            it "shows the correct payment fee amount for the order" do
              payment_fee_field = report_table.last[12]
              expect(payment_fee_field).to eq completed_payment.adjustment.amount
            end
          end
        end

        context 'when a variant override applies' do
          let!(:order) do
            create(:completed_order_with_totals, line_items_count: 1, user: customer.user,
                                                 customer: customer, distributor: distributor)
          end
          let(:overidden_sku) { 'magical_sku' }

          before do
            create(
              :variant_override,
              hub: distributor,
              variant: order.line_items.first.variant,
              sku: overidden_sku
            )
          end

          it 'uses the sku from the variant override' do
            sku_field = report_table.first[23]
            expect(sku_field).to eq overidden_sku
          end
        end
      end
    end
  end
end
