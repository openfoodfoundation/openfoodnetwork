# frozen_string_literal: true

module OrderManagement
  module Reports
    class ReportLoader
      delegate :report_subtypes, to: :base_class

      def initialize(report_type, report_subtype = nil)
        @report_type = report_type
        @report_subtype = report_subtype
      end

      def report_class
        "#{report_module}::#{report_subtype_class}".constantize
      rescue NameError
        raise OrderManagement::Errors::ReportNotFound
      end

      def default_report_subtype
        report_subtypes.first || "base"
      end

      private

      attr_reader :report_type, :report_subtype

      def report_module
        "OrderManagement::Reports::#{report_type.camelize}"
      end

      def report_subtype_class
        subtype = report_subtype || default_report_subtype

        subtype.camelize
      end

      def base_class
        "#{report_module}::Base".constantize
      rescue NameError
        raise OrderManagement::Errors::ReportNotFound
      end
    end
  end
end
