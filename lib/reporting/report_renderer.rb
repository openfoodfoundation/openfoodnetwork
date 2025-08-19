# frozen_string_literal: true

require 'csv'
require 'spreadsheet_architect'
require 'csv'

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

    def metadata_headers
      return [] unless include_metadata?

      rows = []

      # Title from type/subtype (simple, no controller dependency)
      type = @report.params[:report_type]
      sub  = @report.params[:report_subtype]
      if type.present?
        title = [type, sub].compact.map { |s| s.to_s.tr('_', ' ').titleize }.join(' – ')
        rows << ["Report Title", title]
      end

      # Ransack date range
      q = (@report.ransack_params || {}).with_indifferent_access
      from = q[:completed_at_gt] || q[:created_at_gt] || q[:updated_at_gt]
      to   = q[:completed_at_lt] || q[:created_at_lt] || q[:updated_at_lt]
      rows << ["Date range", [from, to].compact.join(" – ")] if from || to

      # Printed timestamp
      rows << ["Printed", (Time.zone || Time).now.strftime("%Y-%m-%d %H:%M:%S %Z")]

      # Other ransack filters (everything except the date keys)
      other = q.dup
      %i[
        completed_at_gt completed_at_lt
        created_at_gt   created_at_lt
        updated_at_gt   updated_at_lt
      ].each { |k| other.delete(k) }

      other.each do |k, v|
        next if v.respond_to?(:blank?) ? v.blank? : v.nil?
        rows << [k.to_s.humanize, v.is_a?(Array) ? v.join(", ") : v.to_s]
      end

      rows << [] # spacer before the sheet
      rows
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

    def to_html(layout: nil)
      ApplicationController.render(
        template: "admin/reports/_table",
        layout:,
        locals: { report: @report }
      )
    end

    def to_csv
      base = SpreadsheetArchitect.to_csv(headers: table_headers, data: table_rows)
      meta = metadata_headers
      return base if meta.empty?

      CSV.generate { |csv| meta.each { |row| csv << row } } + base
    end

    def to_xlsx
      SpreadsheetArchitect.to_xlsx(spreadsheets_options)
    end

    def to_pdf
      html = to_html(layout: "pdf")
      WickedPdf.new.pdf_from_string(html)
    end

    private

    def rendering_options
      @rendering_options ||= begin
        opts = @report.params[:rendering_options] || {}
        opts.respond_to?(:with_indifferent_access) ? opts.with_indifferent_access : opts
      end
    end

    def include_metadata?
      !!rendering_options[:include_metadata]
    end

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
