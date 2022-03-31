# frozen_string_literal: true

module Reporting
  class ReportLoader
    def initialize(report_type, report_subtype = nil)
      @report_type = report_type
      @report_subtype = report_subtype || "base"
    end

    # We currently use two types of report : old report inheriting from ReportObjectReport
    # And new ones inheriting gtom ReportQueryReport
    # They use different namespace and we try to load them both
    def report_class
      "#{report_module}::#{report_type.camelize}Report".constantize
    rescue NameError
      begin
        "#{report_module}::#{report_subtype.camelize}".constantize
      rescue NameError
        raise Reporting::Errors::ReportNotFound
      end
    end

    private

    attr_reader :report_type, :report_subtype

    def report_module
      "Reporting::Reports::#{report_type.camelize}"
    end
  end
end
