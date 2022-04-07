# frozen_string_literal: true

require 'spec_helper'

describe Reporting::ReportRenderer do
  let(:data) {
    [
      { "id" => 1, "name" => "carrots", "quantity" => 3 },
      { "id" => 2, "name" => "onions", "quantity" => 6 }
    ]
  }
  let(:report) {
    OpenStruct.new(
      columns: {
        id: proc { |row| row["id"] },
        name: proc { |row| row["name"] },
        quantity: proc { |row| row["quantity"] },
      },
      rows: data,
      table_headers: data.first.keys,
      table_rows: data.map(&:values)
    )
  }
  let(:service) { described_class.new(report) }

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
end
