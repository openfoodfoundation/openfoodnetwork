# frozen_string_literal: true

require 'spreadsheet_architect'

module Reporting
  class ReportRenderer
    REPORT_FORMATS = [:csv, :json, :html, :xlsx, :pdf].freeze

    def initialize(report)
      @report = report
    end

    # Strip header and summary rows for these formats
    def raw_render?
      @report.params[:report_format].in?(['csv'])
    end

    # Do not format values for these output formats
    def unformatted_render?
      @report.params[:report_format].in?(['json', 'csv'])
    end

    def html_render?
      @report.params[:report_format].in?([nil, '', 'pdf'])
    end

    def display_header_row?
      @report.params[:display_header_row].present? && !raw_render?
    end

    def display_summary_row?
      @report.params[:display_summary_row].present? && !raw_render?
    end

    def table_headers
      @report.table_headers || []
    end

    def table_rows
      @report.table_rows || []
    end

    def as_json(_context_controller = nil)
      @report.rows.map(&:to_h).as_json
    end

    def render_as(target_format)
      unless target_format.to_sym.in?(REPORT_FORMATS)
        raise ActionController::BadRequest, "report_format should be in #{REPORT_FORMATS}"
      end

      public_send("to_#{target_format}")
    end

    def report_from_job(format, user, report_class, params)
      job = ReportJob.new
      JobProcessor.perform_forked(
        job,
        report_class, user, params, format
      )
      job.result
    end

    def to_html(layout: nil)
      ApplicationController.render(
        template: "admin/reports/_table",
        layout: layout,
        locals: { report: @report }
      )
    end

    def to_csv
      SpreadsheetArchitect.to_csv(headers: table_headers, data: table_rows)
    end

    def to_xlsx
      SpreadsheetArchitect.to_xlsx(spreadsheets_options)
    end

    def to_pdf
      html = to_html(layout: "pdf")
      WickedPdf.new.pdf_from_string(html)
    end

    private

    def spreadsheets_options
      {
        headers: table_headers,
        data: table_rows,
        freeze_headers: true,
        row_style: spreadsheets_style,
        header_style: spreadsheets_style.merge({ bg_color: "f7f6f6", bold: true }),
        conditional_row_styles: [
          {
            # Detect header_row: the row is nil except for first cell
            if: proc { |row_data, _row_index|
              row_data.compact.count == 1 && row_data[0].present?
            },
            styles: { font_size: 12, bold: true }
          },
        ],
      }
    end

    def spreadsheets_style
      {
        font_name: 'system-ui',
        alignment: { horizontal: :left, vertical: :bottom }
      }
    end
  end
end
