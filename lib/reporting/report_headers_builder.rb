# frozen_string_literal: true

module Reporting
  class ReportHeadersBuilder
    attr_reader :report

    def initialize(report)
      @report = report
    end

    def table_headers
      report.columns.keys.filter{ |key| key.in?(fields_to_show) }.map do |key|
        translate_header(key)
      end
    end

    def available_headers
      report.columns.keys.map { |key| [translate_header(key), key] }
    end

    def fields_to_show
      fields_in_headers = if report.display_header_row?
                            report.formatted_rules.map { |rule|
                              rule[:fields_used_in_header]
                            }.flatten.reject(&:blank?)
                          else
                            []
                          end
      params_fields_to_show - fields_in_headers
    end

    private

    def translate_header(key)
      # Quite some headers use currency interpolation, so providing it by default
      default_params = { currency: currency_symbol, currency_symbol: currency_symbol }
      report.custom_headers[key] || I18n.t("report_header_#{key}", **default_params)
    end

    def currency_symbol
      Spree::Money.currency_symbol
    end

    def params_fields_to_show
      report.params[:fields_to_show]&.map(&:to_sym) || report.columns.keys
    end
  end
end
