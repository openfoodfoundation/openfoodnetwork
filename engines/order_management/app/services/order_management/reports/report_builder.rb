# frozen_string_literal: true

module OrderManagement
  module Reports
    class ReportBuilder
      def initialize(report)
        @report = report
        @report_rows = []
      end

      def call
        build_rows

        return [] unless @report_rows.length

        order_by(@report.ordering)
        summarise_group(@report.summary_group)
        remove_columns(@report.hide_columns)

        @report_rows
      end

      private

      def build_rows
        @report.collection.each do |object|
          row = @report.report_row(object)

          replace_sensitive_data!(object, row) if mask_data

          @report_rows << row
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
        @report_rows = ReportSummariser.new(group_column, @report_rows, @report).call
      end

      def remove_columns(columns)
        return unless columns.length

        @report_rows.each do |row|
          row.except!(*columns)
        end
      end

      def replace_sensitive_data!(object, row)
        return unless mask_data[:rule].call(object)

        mask_data[:columns].each do |column|
          row[column] = mask_data[:replacement]
        end
      end

      def mask_data
        @report.mask_data
      end
    end
  end
end
