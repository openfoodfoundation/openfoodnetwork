# frozen_string_literal: true

module Reporting
  class ReportRowBuilder
    include ActionView::Helpers::NumberHelper
    include ActionView::Helpers::TagHelper

    attr_reader :report

    def initialize(report, current_user)
      @report = report
      @current_user = current_user
    end

    # Compute the query result item into a result row
    # We use OpenStruct to it's easier to access the properties
    # i.e. row.my_field, rows.sum(&:quantity)
    def build_row(item)
      OpenStruct.new(
        report.columns.transform_values do |column_constructor|
          if column_constructor.is_a?(Symbol)
            report.__send__(column_constructor, item)
          else
            column_constructor.call(item)
          end
        end
      )
    end

    def slice_and_format_row(row)
      result = row.to_h.select { |k, _v| k.in?(report.fields_to_show) }

      unless report.unformatted_render?
        result = result.map { |k, v| [k, format_cell(v, k)] }.to_h
      end
      OpenStruct.new(result)
    end

    def build_header(rule, group_value, group_datas)
      return if rule[:header].blank?

      rule[:header].call(group_value, group_datas.map(&:item), group_datas.map(&:full_row))
    end

    def build_summary_row(rule, group_value, datas)
      return if rule[:summary_row].blank?

      proc_args = [group_value, datas.map(&:item), datas.map(&:full_row)]
      row = rule[:summary_row].call(*proc_args)
      row = add_summary_row_type(row)
      row = slice_and_format_row(OpenStruct.new(row.reverse_merge!(blank_row)))
      add_summary_row_label(row, rule, proc_args)
    end

    private

    def add_summary_row_type(row)
      row.reverse_merge!({ report_row_type: "summary" })
    end

    def add_summary_row_label(row, rule, proc_args)
      previous_key = nil
      label = rule[:summary_row_label]
      label = label.call(*proc_args) if label.respond_to?(:call)
      # Adds Total before first non empty column
      row.each_pair do |key, value|
        if value.present? && previous_key.present? && row[previous_key].blank?
          row[previous_key] = label and break
        end

        previous_key = key
      end
      row
    end

    def blank_row
      report.columns.transform_values { |_v| "" }
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    def format_cell(value, column = nil)
      return "none" if value.nil?

      # Currency
      if report.columns_format[column] == :currency
        format_currency(value)
      # Quantity
      elsif report.columns_format[column] == :quantity && report.html_render?
        format_quantity(value)
      # Numeric
      elsif report.columns_format[column] == :numeric
        format_numeric(value)
      # Percentage, a number between 0 and 1
      elsif report.columns_format[column] == :percentage
        format_percentage(value)
      # Boolean
      elsif value.in? [true, false]
        format_boolean(value)
      # Time
      elsif value.is_a?(Time)
        format_time(value)
      # Date
      elsif value.is_a?(Date)
        format_date(value)
      # Default
      else
        value
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    def format_currency(value)
      value.present? ? number_to_currency(value, unit: Spree::Money.currency_symbol) : ""
    end

    def format_quantity(value)
      content_tag(value > 1 ? :strong : :span, value)
    end

    def format_boolean(value)
      value ? I18n.t(:yes) : I18n.t(:no)
    end

    def format_time(value)
      value.to_datetime.in_time_zone.strftime "%Y-%m-%d %H:%M"
    end

    def format_date(value)
      value.to_datetime.in_time_zone.strftime "%Y-%m-%d"
    end

    def format_numeric(value)
      number_with_delimiter(value)
    end

    def format_percentage(value)
      return '' if value.blank?

      I18n.t('admin.reports.percentage', value: value * 100)
    end
  end
end
