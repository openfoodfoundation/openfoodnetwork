# frozen_string_literal: true

require "spec_helper"

# describe Reporting::Reports::EnterpriseFeeSummary::Renderers::HtmlRenderer do
#   let(:report_klass) { Reporting::Reports::EnterpriseFeeSummary }

#   let!(:permissions) { report_klass::Permissions.new(current_user) }
#   let!(:parameters) { report_klass::Parameters.new }
#   let!(:controller) { Reporting::Reports::EnterpriseFeeSummariesController.new }
#   let!(:service) { report_klass::ReportService.new(permissions, parameters) }
#   let!(:renderer) { described_class.new(service) }

#   let!(:enterprise_fee_type_totals) do
#     [
#       report_klass::ReportData::EnterpriseFeeTypeTotal.new(
#         fee_type: "Fee Type A",
#         enterprise_name: "Enterprise A",
#         fee_name: "Fee A",
#         customer_name: "Custoemr A",
#         fee_placement: "Fee Placement A",
#         fee_calculated_on_transfer_through_name: "Transfer Enterprise A",
#         tax_category_name: "Tax Category A",
#         total_amount: "1.00"
#       ),
#       report_klass::ReportData::EnterpriseFeeTypeTotal.new(
#         fee_type: "Fee Type B",
#         enterprise_name: "Enterprise B",
#         fee_name: "Fee C",
#         customer_name: "Custoemr D",
#         fee_placement: "Fee Placement E",
#         fee_calculated_on_transfer_through_name: "Transfer Enterprise F",
#         tax_category_name: "Tax Category G",
#         total_amount: "2.00"
#       )
#     ]
#   end

#   let(:current_user) { nil }

#   before do
#     allow(service).to receive(:list) { enterprise_fee_type_totals }
#   end

#   it "generates header values" do
#     header_row = renderer.header

#     # Test all header cells have values
#     expect(header_row.length).to eq(8)
#     expect(header_row.all?(&:present?)).to be_truthy
#   end

#   it "generates data rows" do
#     header_row = renderer.header
#     result = renderer.data_rows

#     expect(result.length).to eq(2)

#     # Test random cells
#     expect(result[0][header_row.index(i18n_translate("header.fee_type"))]).to eq("Fee Type A")
#     expect(result[0][header_row.index(i18n_translate("header.total_amount"))]).to eq("1.00")
#     expect(result[1][header_row.index(i18n_translate("header.total_amount"))]).to eq("2.00")
#   end

#   def i18n_translate(key)
#     I18n.t(key, scope: i18n_scope)
#   end

#   def i18n_scope
#     "order_management.reports.enterprise_fee_summary.formats.csv"
#   end
# end
