# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Reporting::ReportMetadataBuilder do
  include ActiveSupport::Testing::TimeHelpers

  let(:from_key) { described_class::DATE_FROM_KEYS.first }
  let(:to_key)   { described_class::DATE_TO_KEYS.first }

  let(:params) do
    { report_type: :order_cycle_customer_totals, report_subtype: 'by_distributor' }
  end

  let(:ransack_params) do
    {
      from_key => '2025-01-01',
      to_key => '2025-01-31',
      :status_in => %w[paid shipped],
      :hub_id_eq => '42'
    }
  end

  # minimal report double exposing what the builder reads
  let(:report) do
    double('Report', params:, ransack_params:)
  end

  subject(:builder) { described_class.new(report, nil) }

  it 'builds a title row from report_type and subtype' do
    expect(builder.title_rows).to eq([['Report Title',
                                       'Order Cycle Customer Totals – By Distributor']])
  end

  it 'builds a date range row from ransack params' do
    expect(builder.date_range_rows).to eq([['Date range', '2025-01-01 – 2025-01-31']])
  end

  it 'builds a printed row using Time.zone in a deterministic way' do
    travel_to(Time.zone.parse('2025-06-13 10:20:30 UTC')) do
      expect(builder.printed_rows).to eq([['Printed', '2025-06-13 10:20:30 UTC']])
    end
  end

  it 'builds other filter rows, excluding date keys and humanizing names' do
    rows = builder.other_filter_rows
    expect(rows).to include(['Status in', 'paid, shipped'])
    expect(rows).to include(['Hub id eq', '42'])
  end

  it 'assembles all rows in order and ends with a spacer row' do
    travel_to(Time.zone.parse('2025-06-13 10:20:30 UTC')) do
      rows = builder.rows
      expect(rows.first).to eq(['Report Title', 'Order Cycle Customer Totals – By Distributor'])
      expect(rows).to include(['Date range', '2025-01-01 – 2025-01-31'])
      expect(rows).to include(['Printed', '2025-06-13 10:20:30 UTC'])
      expect(rows.last).to eq([])
    end
  end
end

# --- Coverage for metadata headers (keeps OFN spec style) ---
RSpec.describe Reporting::ReportRenderer do
  let(:user) { create(:user) }
  let(:report_params) do
    {
      # flag the renderer to include metadata
      include_metadata: true,
      # set a recognizable title source
      report_type: :order_cycle_customer_totals,
      report_subtype: 'by_distributor'
    }
  end

  let(:ransack_params) do
    # any pair of from/to keys the builder recognizes is fine;
    # use created_at as it's commonly present in OFN reports.
    { created_at_gteq: '2025-01-01', created_at_lteq: '2025-01-31', status_in: %w[paid shipped] }
  end

  let(:report) {
    double('Report', params: report_params, ransack_params:, user:)
  }

  subject { described_class.new(report) }

  describe '#metadata_headers' do
    it 'returns [] when include_metadata? is false' do
      allow(subject).to receive(:include_metadata?).and_return(false)
      expect(subject.metadata_headers).to eq([])
    end

    it 'builds rows via ReportMetadataBuilder when include_metadata? is true' do
      # If include_metadata? relies on params, you can omit this stub;
      # it’s harmless and makes the intent explicit.
      allow(subject).to receive(:include_metadata?).and_return(true)

      rows = subject.metadata_headers
      expect(rows).to be_an(Array)
      expect(rows).not_to be_empty

      # Structure/labels we added in the builder:
      labels = rows.map(&:first)
      expect(labels).to include('Report Title')
      expect(labels).to include('Date range').or include('Date Range')
      expect(labels).to include('Printed')
    end
  end
end
