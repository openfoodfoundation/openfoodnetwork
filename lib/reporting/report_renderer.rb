# frozen_string_literal: true

require 'spreadsheet_architect'

module Reporting
  class ReportRenderer
    def initialize(report)
      @report = report
    end

    def table_headers
      @report.respond_to?(:report_data) ? @report.report_data.columns : @report.table_headers
    end

    def table_rows
      @report.respond_to?(:report_data) ? @report.report_data.rows : @report.table_rows
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

    def to_pdf
      WickedPdf.new.pdf_from_string(
        ActionController::Base.new.render_to_string(
          template: 'admin/reports/_table',
          layout: 'pdf',
          locals: { report: self }
        )
      )
    end
  end
end
