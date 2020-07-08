# frozen_string_literal: true

module OrderManagement
  module Reports
    class ReportOrderer
      def initialize(report_rows, sorting_rules)
        @report_rows = report_rows
        @sorting_rules = sorting_rules
      end

      def call
        return unless sorting_rules.length

        @report_rows.sort! do |row1, row2|
          sort_key1(row1, row2) <=> sort_key2(row1, row2)
        end
      end

      private

      attr_reader :sorting_rules

      def ascending_columns
        sorting_rules.select { |key| key.to_s.ends_with?('!') }
      end

      def desc_columns
        sorting_rules.map { |key| key.to_s.sub(/\!\z/, '').to_sym }
      end

      def asc_columns
        ascending_columns.map { |key| key.to_s.sub(/\!\z/, '').to_sym }
      end

      def sort_key1(row1, row2)
        desc_columns.map { |column| asc_columns.include?(column) ? row2[column] : row1[column] }
      end

      def sort_key2(row1, row2)
        desc_columns.map { |column| asc_columns.include?(column) ? row1[column] : row2[column] }
      end
    end
  end
end
