# frozen_string_literal: true

require 'spreadsheet_architect'

module Reporting
  class ReportRenderer
    def initialize(report)
      @report = report
    end

    def table_headers
      @report.report_data.columns
    end

    def table_rows
      @report.report_data.rows
    end

    def as_json
      @report.report_data.as_json
    end

    def as_arrays
      @as_arrays ||= [table_headers] + table_rows
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
  end
end
