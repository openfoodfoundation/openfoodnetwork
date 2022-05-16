# frozen_string_literal: true

require "spec_helper"

# describe Reporting::Reports::EnterpriseFeeSummary::Renderers::CsvRenderer do
#   let(:report_klass) { Reporting::Reports::EnterpriseFeeSummary }

#   let!(:permissions) { report_klass::Permissions.new(current_user) }
#   let!(:parameters) { report_klass::Parameters.new }
#   let!(:service) { report_klass::ReportService.new(permissions, parameters) }
#   let!(:renderer) { described_class.new(service) }

#   # Context which will be passed to the renderer. The response object
#   # is not automatically prepared,
#   # so this has to be assigned explicitly.
#   let!(:response) { ActionDispatch::TestResponse.new }
#   let!(:request) { double(Rack::Request) }
#   let!(:controller) do
#     ActionController::Base.new.tap do |controller_mock|
#       controller_mock.instance_variable_set(:@_response, response)
#       controller_mock.instance_variable_set(:@_request, request)
#     end
#   end

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
#     allow(request).to receive_messages(variant: double(Spree::Variant),
#                                        should_apply_vary_header?: true)
#   end

#   it "generates CSV header" do
#     renderer.render(controller)
#     result = response.body
#     csv = CSV.parse(result)
#     header_row = csv[0]

#     # Test all header cells have values
#     expect(header_row.length).to eq(8)
#     expect(header_row.all?(&:present?)).to be_truthy
#   end

#   it "generates CSV data rows" do
#     renderer.render(controller)
#     result = response.body
#     csv = CSV.parse(result, headers: true)

#     expect(csv.length).to eq(2)

#     # Test random cells
#     expect(csv[0][i18n_translate("header.fee_type")]).to eq("Fee Type A")
#     expect(csv[0][i18n_translate("header.total_amount")]).to eq("1.00")
#     expect(csv[1][i18n_translate("header.total_amount")]).to eq("2.00")
#   end

#   it "generates filename correctly" do
#     Timecop.freeze(Time.zone.local(2018, 10, 9, 7, 30, 0)) do
#       filename = renderer.__send__(:filename)
#       expect(filename).to eq("enterprise_fee_summary_20181009.csv")
#     end
#   end

#   def i18n_translate(key)
#     I18n.t(key, scope: i18n_scope)
#   end

#   def i18n_scope
#     "order_management.reports.enterprise_fee_summary.formats.csv"
#   end
# end
