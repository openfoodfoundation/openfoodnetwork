# frozen_string_literal: true

module Reports
  class ReportOrderer
    def initialize(report)
      @report = report
    end

    def call
      return unless ordering.length

      sort_rows
      order_subgroups
    end

    private

    attr_reader :report
    delegate :report_rows, :ordering, :order_subgroup, to: :report

    def sort_rows
      report_rows.sort! do |row1, row2|
        sort_key1(row1, row2) <=> sort_key2(row1, row2)
      end
    end

    def ascending_columns
      ordering.select { |key| key.to_s.ends_with?('!') }
    end

    def desc_columns
      ordering.map { |key| key.to_s.sub(/\!\z/, '').to_sym }
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

    def order_subgroups
      return report_rows unless order_subgroup

      report.report_rows = report_rows.
        group_by{ |row| row[order_subgroup[:group]] }.
        values.
        sort_by { |item| item.first[order_subgroup[:order]] }.
        flatten
    end
  end
end
