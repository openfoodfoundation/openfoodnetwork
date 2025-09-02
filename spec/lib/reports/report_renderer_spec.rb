# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Reporting::ReportRenderer do
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

# --- metadata headers coverage ---
RSpec.describe Reporting::ReportRenderer do
  let(:user) { create(:user) }

  # Use the same keys the builder recognizes so we actually get a "Date range" row
  let(:from_key) { Reporting::ReportMetadataBuilder::DATE_FROM_KEYS.first }
  let(:to_key)   { Reporting::ReportMetadataBuilder::DATE_TO_KEYS.first }

  let(:meta_report) do
    double(
      'Report',
      params: {
        include_metadata: true,
        report_type: :order_cycle_customer_totals,
        report_subtype: 'by_distributor'
      },
      ransack_params: {
        from_key => '2025-01-01',
        to_key => '2025-01-31',
        :status_in => %w[paid shipped]
      },
      user:
    )
  end

  let(:renderer) { described_class.new(meta_report) }

  describe '#metadata_headers' do
    it 'returns [] when include_metadata? is false' do
      allow(renderer).to receive(:include_metadata?).and_return(false)
      expect(renderer.metadata_headers).to eq([])
    end

    it 'builds rows via ReportMetadataBuilder when include_metadata? is true' do
      allow(renderer).to receive(:include_metadata?).and_return(true)
      rows = renderer.metadata_headers

      labels = rows.map(&:first)
      expect(labels).to include('Report Title')
      expect(labels).to include('Date range') # present because we used the recognized keys
      expect(labels).to include('Printed')
    end
  end
end
