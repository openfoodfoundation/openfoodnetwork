# frozen_string_literal: true

require 'spec_helper'

describe Reporting::ReportRenderer do
  let(:data) {
    [
      { "id" => 1, "name" => "carrots", "quantity" => 3 },
      { "id" => 2, "name" => "onions", "quantity" => 6 }
    ]
  }
  let(:report_data) { ActiveRecord::Result.new(data.first.keys, data.map(&:values)) }
  let(:report) { OpenStruct.new(report_data: report_data)
  }
  let(:service) { described_class.new(report) }

  describe "#table_headers" do
    it "returns the report's table headers" do
      expect(service.table_headers).to eq ["id", "name", "quantity"]
    end
  end

  describe "#table_rows" do
    it "returns the report's table rows" do
      expect(service.table_rows).to eq [
        [1, "carrots", 3],
        [2, "onions", 6]
      ]
    end
  end

  describe "#as_json" do
    it "returns the report's data as hashes" do
      expect(service.as_json).to eq data.as_json
    end
  end

  describe "#as_arrays" do
    it "returns the report's data as arrays" do
      expect(service.as_arrays).to eq [
        ["id", "name", "quantity"],
        [1, "carrots", 3],
        [2, "onions", 6]
      ]
    end
  end

  describe "exporting to different formats" do
    let(:spreadsheet_architect) { SpreadsheetArchitect }
    before do
      allow(spreadsheet_architect).to receive(:to_csv) {}
      allow(spreadsheet_architect).to receive(:to_ods) {}
      allow(spreadsheet_architect).to receive(:to_xlsx) {}
    end

    describe "#to_csv" do
      it "exports as csv" do
        service.to_csv

        expect(spreadsheet_architect).to have_received(:to_csv).
          with(headers: service.table_headers, data: service.table_rows)
      end
    end

    describe "#to_ods" do
      it "exports as ods" do
        service.to_ods

        expect(spreadsheet_architect).to have_received(:to_ods).
          with(headers: service.table_headers, data: service.table_rows)
      end
    end

    describe "#to_xslx" do
      it "exports as xlsx" do
        service.to_xlsx

        expect(spreadsheet_architect).to have_received(:to_xlsx).
          with(headers: service.table_headers, data: service.table_rows)
      end
    end
  end
end
