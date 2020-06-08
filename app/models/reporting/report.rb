# frozen_string_literal: true

require 'spreadsheet_architect'

module Reporting
  class Report
    delegate :to_json, to: :data_hashes
    attr_reader :options

    def initialize(current_user, ransack_params, options = {})
      @current_user = current_user
      @ransack_params = ransack_params.with_indifferent_access
      @options = ( options || {} ).with_indifferent_access
      @report_rows = []

      build_report
    end

    def headers
      @report_rows.first.andand.keys || []
    end

    def table_headers
      data_arrays.first
    end

    def table_rows
      data_arrays.drop(1)
    end

    def to_csv
      ::SpreadsheetArchitect.to_csv(headers: table_headers, data: table_rows)
    end

    def to_ods
      ::SpreadsheetArchitect.to_ods(headers: table_headers, data: table_rows)
    end

    def to_xlsx
      ::SpreadsheetArchitect.to_xlsx(headers: table_headers, data: table_rows)
    end

    def data_hashes
      @report_rows
    end

    def data_arrays
      @data_arrays ||= rows_as_arrays
    end

    private

    attr_reader :current_user, :ransack_params

    def build_report
      @report_rows = ReportBuilder.new(@report_rows, self).call
    end

    def rows_as_arrays
      report_array = [headers]

      @report_rows.each do |row|
        report_array << row_with_summaries(row)
      end

      report_array
    end

    def row_with_summaries(row)
      summary_row_title = row.delete :summary_row_title
      row_values = row.values
      row_values[0] = summary_row_title if summary_row_title

      row_values
    end

    # Implement the methods below to create a custom report.

    def collection; end

    def report_row(object)
      {}
    end

    def ordering
      []
    end

    def summary_group
      nil
    end

    def summary_row
      []
    end

    def hide_columns
      []
    end
  end
end
