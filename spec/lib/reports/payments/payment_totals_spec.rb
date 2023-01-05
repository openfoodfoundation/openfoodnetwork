# frozen_string_literal: true

require 'spec_helper'

module Reporting
  module Reports
    module Payments
      describe PaymentTotals do
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
            PaymentTotals.new(current_user, params)
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
                                                 "Total ($)",
                                                 "EFT ($)",
                                                 "PayPal ($)",
                                                 "Outstanding Balance ($)"
                                               ])
          end

          it "translates payment_states" do
            first_row_first_column_value = report_table.first.first
            expect(first_row_first_column_value).to eq "balance due"
          end
        end
      end
    end
  end
end
