# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Reporting::ReportMetadataBuilder do
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

  let(:report) { double('Report', params:, ransack_params:) }

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

      # Other filters (humanized keys)
      expect(rows).to include(['Status in', 'paid, shipped'])
      expect(rows).to include(['Hub id eq', '42'])

      # Spacer
      expect(rows.last).to eq([])
    end
  end

  describe "#display_metadata_rows_param?" do
    it "casts truthy string 'true' to true" do
      report_with_true = double(
        "Report",
        params: params.merge(rendering_options: { display_metadata_rows: "true" }),
        ransack_params: ransack_params
      )

      builder_with_true = described_class.new(report_with_true, nil)
      expect(builder_with_true.display_metadata_rows_param?).to be true
    end

    it "casts '0' to false" do
      report_with_zero = double(
        "Report",
        params: params.merge(rendering_options: { display_metadata_rows: "0" }),
        ransack_params: ransack_params
      )

      builder_with_zero = described_class.new(report_with_zero, nil)
      expect(builder_with_zero.display_metadata_rows_param?).to be false
    end

    it "returns false when key is missing" do
      report_without_key = double(
        "Report",
        params: params, # no :rendering_options / :display_metadata_rows present
        ransack_params: ransack_params
      )

      builder_without_key = described_class.new(report_without_key, nil)
      expect(builder_without_key.display_metadata_rows_param?).to be false
    end
  end
end
