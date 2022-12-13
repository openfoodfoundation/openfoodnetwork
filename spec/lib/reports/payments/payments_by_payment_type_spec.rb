# frozen_string_literal: true

require 'spec_helper'

module Reporting
  module Reports
    module Payments
      describe PaymentsByPaymentType do
        let!(:distributor) { create(:distributor_enterprise, name: "Apple Market") }
        let!(:customer) { create(:customer, enterprise: distributor, user: user, code: "JHN") }
        let(:user) { create(:user, email: "john@example.net") }
        let(:current_user) { distributor.owner }
        let(:params) { { display_summary_row: true, q: search_params } }
        let(:search_params) {
          { completed_at_gt: 1.week.before(order_date), completed_at_lt: 1.week.after(order_date) }
        }
        let(:report) { described_class.new(current_user, params) }
        let(:order_date) { Date.parse("2022-05-26") }

        let(:report_table) do
          report.table_rows
        end

        let(:table_headers) do
          report.table_headers
        end

        context "displaying payments by payment type" do
          let!(:order) {
            create(
              :order_ready_to_ship,
              user: customer.user,
              customer: customer, distributor: distributor,
              completed_at: order_date,
            )
          }
          let(:completed_payment) { order.payments.completed.first }

          it "generates the report" do
            expect(report_table.length).to eq(1)
          end

          it "Should return headers" do
            expect(report.table_headers).to eq([
                                                 "Payment State",
                                                 "Distributor",
                                                 "Payment Type",
                                                 "Total ($)"
                                               ])
          end

          it "translates payment_states" do
            first_row_first_column_value = report_table.first.first
            translated_payment_state = i18n_translate("paid")
            expect(first_row_first_column_value).to eq translated_payment_state
          end

          # Helper methods for example group
          def i18n_translate(translation_key, options = {})
            I18n.t("js.admin.orders.payment_states.#{translation_key}", **options)
          end
        end
      end
    end
  end
end
