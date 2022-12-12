# frozen_string_literal: true

require 'spec_helper'

module Reporting
  module Reports
    module Payments
      describe ItemisedPaymentTotals do
        context "As a site admin" do
          let(:user) do
            user = create(:user)
            user.spree_roles << Spree::Role.find_or_create_by!(name: 'admin')
            user
          end
          subject do
            Base.new user, {}
          end

          let!(:distributor) { create(:distributor_enterprise) }

          let!(:order) do
            create(:completed_order_with_totals, line_items_count: 1, distributor: distributor)
          end

          let(:current_user) { distributor.owner }
          let(:params) { { display_summary_row: false } }
          let(:report) do
            ItemisedPaymentTotals.new(current_user, params)
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

          it "Should return headers" do
            expect(report.table_headers).to eq([
                                                "Payment State",
                                                "Distributor",
                                                "Product Total ($)",
                                                "Shipping Total ($)",
                                                "Outstanding Balance ($)",
                                                "Total ($)"
                                                ])
          end
          it "translates payment_states" do
            first_row_first_column_value = report_table.first.first
            translated_payment_state = i18n_translate("balance_due")
            expect(translated_payment_state).to eq first_row_first_column_value
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
