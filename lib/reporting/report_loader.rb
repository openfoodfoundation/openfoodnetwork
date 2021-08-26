# frozen_string_literal: true

module Reporting
  class ReportLoader
    delegate :report_subtypes, to: :base_class

    def initialize(report_type, report_subtype = nil)
      @report_type = report_type
      @report_subtype = report_subtype
    end

    def report_class
      "#{report_module}::#{report_subtype_class}".constantize
    rescue NameError
      raise Reporting::Errors::ReportNotFound
    end

    def default_report_subtype
      report_subtypes.first || "base"
    end

    private

    attr_reader :report_type, :report_subtype

    def report_module
      "Reporting::Reports::#{report_type.camelize}"
    end

    def report_subtype_class
      (report_subtype || default_report_subtype).camelize
    end

    def base_class
      "#{report_module}::Base".constantize
    rescue NameError
      raise Reporting::Errors::ReportNotFound
    end
  end
end
