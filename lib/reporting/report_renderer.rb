# frozen_string_literal: true

require 'spreadsheet_architect'

module Reporting
  class ReportRenderer
    def initialize(report)
      @report = report
    end

    def table_headers
      @report.table_headers || []
    end

    def table_rows
      @report.table_rows || []
    end

    def as_json
      table_rows.map do |row|
        result = {}
        table_headers.zip(row) { |a, b| result[a.to_sym] = b }
        result
      end.as_json
    end

    def as_arrays
      @as_arrays ||= [table_headers] + table_rows
    end

    def to_csv(_context_controller = nil)
      SpreadsheetArchitect.to_csv(headers: table_headers, data: table_rows)
    end

    def to_ods(_context_controller = nil)
      SpreadsheetArchitect.to_ods(headers: table_headers, data: table_rows)
    end

    def to_xlsx(_context_controller = nil)
      SpreadsheetArchitect.to_xlsx(headers: table_headers, data: table_rows)
    end

    def to_pdf(context_controller)
      WickedPdf.new.pdf_from_string(
        context_controller.render_to_string(
          template: 'admin/reports/_table',
          layout: 'pdf',
          locals: { report: @report }
        )
      )
    end
  end
end
