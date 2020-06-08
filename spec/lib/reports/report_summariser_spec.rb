# frozen_string_literal: true

require 'spec_helper'

describe Reports::ReportSummariser do
  let(:report_rows) {
    [
      { id: 1, supplier: "Fred's Farm", product: "Carrots", quantity: 3 },
      { id: 2, supplier: "Fred's Farm", product: "Onions", quantity: 6 },
      { id: 3, supplier: "Bessie's Bakery", product: "Bread", quantity: 4 },
      { id: 4, supplier: "Jenny's Jams", product: "Jam", quantity: 5 },
    ]
  }
  let(:group_column) { :supplier }
  let(:report_options) { { exclude_summaries: false } }
  let(:report_object) { instance_double(Reports::ReportTemplate) }
  let(:service) { described_class.new(report_object) }

  before do
    allow(report_object).to receive(:report_rows) { report_rows }
    allow(report_object).to receive(:report_rows=)
    allow(report_object).to receive(:options) { report_options }
    allow(report_object).to receive(:headers) { [:id, :supplier, :product, :quantity] }
    allow(report_object).to receive(:summary_group) { group_column }
    allow(report_object).to receive(:summary_row) {
      { title: "TOTALS", sum: [:quantity] }
    }
  end

  describe "adding summary rows" do
    it "inserts summary rows based on given rules" do
      expect(service.call).to eq(
        [
          { id: 1, supplier: "Fred's Farm", product: "Carrots", quantity: 3 },
          { id: 2, supplier: "Fred's Farm", product: "Onions", quantity: 6 },
          { id: "", supplier: "", product: "", quantity: 9, summary_row_title: "TOTALS" },
          { id: 3, supplier: "Bessie's Bakery", product: "Bread", quantity: 4 },
          { id: "", supplier: "", product: "", quantity: 4, summary_row_title: "TOTALS" },
          { id: 4, supplier: "Jenny's Jams", product: "Jam", quantity: 5 },
          { id: "", supplier: "", product: "", quantity: 5, summary_row_title: "TOTALS" },
        ]
      )
    end
  end
end
