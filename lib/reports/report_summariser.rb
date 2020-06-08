# frozen_string_literal: true

module Reports
  class ReportSummariser
    def initialize(report)
      @report = report
    end

    def call
      return if skip_summaries?

      insert_summary_rows
    end

    private

    attr_accessor :report
    delegate :report_rows, :summary_group, :summary_row, to: :report

    def skip_summaries?
      summary_group.blank? || summary_row.blank? || exclude_summaries?
    end

    def insert_summary_rows
      grouped_rows = []
      previous_grouping = nil

      report_rows.each_with_index do |row, row_index|
        current_grouping = row[summary_group]

        if previous_grouping.present? && current_grouping != previous_grouping
          grouped_rows << build_summary_row(summary_group, previous_grouping, summary_row)
        end

        grouped_rows << row
        previous_grouping = current_grouping

        if last_row?(row_index)
          grouped_rows << build_summary_row(summary_group, previous_grouping, summary_row)
        end
      end

      report.report_rows = grouped_rows
    end

    def build_summary_row(group_column, group_key, options)
      summary = initialize_empty_row
      group_rows = report_rows.select{ |row| row[group_column] == group_key }

      summary[:summary_row_title] = options[:title]

      (options[:sum] || []).each do |sum_column|
        summary[sum_column] = group_rows.sum{ |group_row| group_row[sum_column] }
      end

      (options[:show_first] || []).each do |first_column|
        summary[first_column] = group_rows.first[first_column]
      end

      summary
    end

    def initialize_empty_row
      row = {}
      report_headers.each do |key|
        row[key.to_sym] = ""
      end

      row
    end

    def last_row?(row_index)
      report_rows.length == row_index + 1
    end

    def exclude_summaries?
      report.options[:exclude_summaries]
    end

    def report_headers
      report_rows.first&.keys
    end
  end
end
