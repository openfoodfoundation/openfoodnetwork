# frozen_string_literal: true

module Reporting
  class ReportRuler
    def initialize(report)
      @report = report
    end

    def formatted_rules
      @formatted_rules ||= @report.rules.map { |rule| format_rule(rule) }
    end

    def header_option?
      formatted_rules.find { |rule| rule[:header].present? }
    end

    def summary_row_option?
      formatted_rules.find { |rule| rule[:summary_row].present? }
    end

    private

    def format_rule(rule)
      handle_header_shortcuts(rule)
      default_values = {
        header_class: "h2",
        summary_row_class: "text-bold",
        summary_row_label: I18n.t('admin.reports.total')
      }
      rule.reverse_merge(default_values)
    end

    def handle_header_shortcuts(rule)
      # Handles shortcut header: :supplier
      rule[:header] = Array(rule[:header]) if rule[:header].is_a?(Symbol)
      # Handles shortcut header: [:last_name, :first_name]
      case rule[:header]
      when true
        handle_shortcut_header_true(rule)
      when proc { |r| r.is_a?(Array) }
        handle_shortcut_header_array(rule)
      end
      rule[:fields_used_in_header] ||= [rule[:group_by]] if rule[:group_by].is_a?(Symbol)
    end

    # header: true
    # Use the grouping key for header
    def handle_shortcut_header_true(rule)
      rule[:header] = proc { |key, _items, _rows| key }
    end

    # header: [:first_name, :last_name]
    # Use the list of properties ot build the header
    def handle_shortcut_header_array(rule)
      rule[:fields_used_in_header] ||= rule[:header]
      fields = rule[:header]
      rule[:header] = proc do |_key, _items, rows|
        fields.map { |field| rows.first[field] }.reject(&:blank?).join(' ')
      end
    end
  end
end
