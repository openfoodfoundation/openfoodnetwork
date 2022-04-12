# frozen_string_literal: true

module Reporting
  class ReportLoader
    def initialize(report_type, report_subtype = nil)
      @report_type = report_type
      @report_subtype = report_subtype
    end

    def report_class
      "#{report_module}::#{report_subtype.camelize}".constantize
    rescue NameError
      begin
        "#{report_module}::Base".constantize
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
