# frozen_string_literal: true

RSpec.describe Reporting::ReportMetadataBuilder do
  let(:from_key) { described_class::DATE_FROM_KEYS.first }
  let(:to_key)   { described_class::DATE_TO_KEYS.first }

  let(:params) do
    { report_type: :order_cycle_customer_totals, report_subtype: 'by_distributor' }
  end

  let(:ransack_params) do
    {
      from_key => '2025-01-01',
      to_key => '2025-01-31'
    }
  end

  let(:report) { instance_double('Report', params:, ransack_params:) }

  subject(:builder) { described_class.new(report, nil) }

  it 'assembles rows with title, date range, printed, other filters, and spacer' do
    travel_to(Time.zone.parse('2025-06-13 10:20:30 UTC')) do
      rows = builder.rows

      # Title
      expect(rows).to include(['Report Title', 'Order Cycle Customer Totals - By Distributor'])

      # Date range
      expect(rows).to include(['Date Range', '2025-01-01 - 2025-01-31'])

      # Printed timestamp
      printed = rows.find { |r| r.first == 'Printed' }
      expect(printed).to eq(['Printed', '2025-06-13 10:20:30 UTC'])

      # Spacer
      expect(rows.last).to eq([])
    end
  end
end
