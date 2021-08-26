# frozen_string_literal: true

module Reporting
  module Errors
    class Base < StandardError
      def i18n_error_scope
        'admin.reports.errors'
      end
    end

    class NoReportType < Base
      def message
        I18n.t('no_report_type', scope: i18n_error_scope)
      end
    end

    class ReportNotFound < Base
      def message
        I18n.t('report_not_found', scope: i18n_error_scope)
      end
    end

    class MissingQueryParams < Base
      def message
        I18n.t('missing_ransack_params', scope: i18n_error_scope)
      end
    end
  end
end
