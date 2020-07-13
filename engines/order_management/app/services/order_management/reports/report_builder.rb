# frozen_string_literal: true

module OrderManagement
  module Reports
    class ReportBuilder
      def initialize(report)
        @report = report
      end

      def call
        build_rows

        return [] unless report_rows.length

        order_results
        insert_summaries
        remove_hidden_columns
      end

      private

      attr_reader :report
      delegate :report_rows, :hide_columns, :mask_data, to: :report

      def build_rows
        report.collection.each do |object|
          row = report.report_row(object)

          replace_sensitive_data!(object, row) if mask_data

          report_rows << row
        end
      end

      def order_results
        ReportOrderer.new(report).call
      end

      def insert_summaries
        ReportSummariser.new(report).call
      end

      def remove_hidden_columns
        return unless hide_columns.length

        report_rows.each do |row|
          row.except!(*hide_columns)
        end
      end

      def replace_sensitive_data!(object, row)
        return unless mask_data[:rule].call(object)

        mask_data[:columns].each do |column|
          row[column] = mask_data[:replacement]
        end
      end
    end
  end
end
