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
  let(:subject) { described_class.new(report) }

  describe ".as_json" do
    it "returns the report's data as hashes" do
      expect(subject.as_json).to eq data.as_json
    end
  end

  describe ".render_as" do
    it "raise an error if format is not supported" do
      expect { subject.render_as("give_me_everything") }.to raise_error
    end
  end
end
