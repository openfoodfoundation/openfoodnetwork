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

    def build_report
      build_rows
      order_by(ordering)
      summarise_group(summary_group)
      remove_columns(*hide_columns)
    end

    def build_rows
      collection.each do |object|
        @report_rows << report_row(object)
      end
    end

    def order_by(columns)
      return unless columns.length

      reverse_columns = columns.select { |head| head.to_s.ends_with?('!') }
      sort = columns.map { |head| head.to_s.sub(/\!\z/, '').to_sym }
      reverse_sort = reverse_columns.map { |head| head.to_s.sub(/\!\z/, '').to_sym }

      @report_rows.sort! do |row1, row2|
        key1 = sort.map { |column| reverse_sort.include?(column) ? row2[column] : row1[column] }
        key2 = sort.map { |column| reverse_sort.include?(column) ? row1[column] : row2[column] }
        key1 <=> key2
      end
    end

    def summarise_group(group_column)
      @report_rows = ReportSummariser.new(group_column, @report_rows, self).call
    end

    def remove_columns(columns)
      return unless columns.length

      @report_rows.each do |row|
        row.except!(columns)
      end
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
