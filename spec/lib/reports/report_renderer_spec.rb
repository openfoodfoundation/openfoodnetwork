# frozen_string_literal: true

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
      expect {
        subject.render_as("give_me_everything")
      }.to raise_error(ActionController::BadRequest)
    end
  end

  # metadata headers

  describe '#metadata_headers' do
    let(:user) { create(:user) }
    let(:from_key) { Reporting::ReportMetadataBuilder::DATE_FROM_KEYS.first }
    let(:to_key)   { Reporting::ReportMetadataBuilder::DATE_TO_KEYS.first }

    let(:meta_report) do
      double(
        'MetaReport',
        rows: data,
        params: {
          display_metadata_rows: true,
          report_type: :order_cycle_customer_totals,
          report_subtype: 'by_distributor',
          report_format: 'csv'
        },
        ransack_params: {
          from_key => '2025-01-01',
          to_key => '2025-01-31'
        },
        user:,
        table_headers: nil
      )
    end

    let(:renderer) { described_class.new(meta_report) }

    it 'appends empty base headers when report.table_headers is nil
    and metadata rows are enabled' do
      expect(renderer.table_headers.last).to eq []
    end

    it 'builds rows via ReportMetadataBuilder when display_metadata_rows?
      is true and report_format is csv' do
        rows = renderer.metadata_headers

        labels = rows.map(&:first)
        expect(labels).to include('Report Title')
        expect(labels).to include('Date Range')
        expect(labels).to include('Printed')

        values = rows.map(&:second)
        expect(values).to include('Order Cycle Customer Totals - By Distributor')
        expect(values).to include('2025-01-01 - 2025-01-31')
        expect(values).to include(Time.now.utc.strftime('%F %T %Z'))
      end
  end
end
