# frozen_string_literal: true

require 'spreadsheet_architect'

module Reports
  class ReportRenderer
    def initialize(report)
      @report = report
    end

    def table_headers
      as_arrays.first
    end

    def table_rows
      as_arrays.drop(1)
    end

    def as_hashes
      report_rows
    end

    def as_arrays
      @as_arrays ||= rows_as_arrays
    end

    def to_csv
      SpreadsheetArchitect.to_csv(headers: table_headers, data: table_rows)
    end

    def to_ods
      SpreadsheetArchitect.to_ods(headers: table_headers, data: table_rows)
    end

    def to_xlsx
      SpreadsheetArchitect.to_xlsx(headers: table_headers, data: table_rows)
    end

    private

    def report_rows
      @report.report_rows
    end

    def rows_as_arrays
      report_array = [header_row]

      report_rows.each do |row|
        report_array << row_or_summary(row)
      end

      report_array
    end

    def header_row
      report_rows.first.keys - [:summary_row_title]
    end

    def row_or_summary(row)
      summary_row_title = row.delete :summary_row_title
      row_values = row.values
      row_values[0] = summary_row_title if summary_row_title

      row_values
    end
  end
end
