# frozen_string_literal: true

module OrderManagement
  module Api
    class ReportsController < ::Api::BaseController
      include OrderManagement::Concerns::ReportsActions
      before_action :authorize, :validate_params

      rescue_from OrderManagement::Errors::Base, with: :render_error

      def show
        @report = report_class.new(current_api_user, ransack_params, report_options)

        render_report
      end

      private

      def authorize
        authorize! :admin, Enterprise
      end

      def validate_params
        if report_type.blank?
          raise OrderManagement::Errors::ReportNotFound,
                I18n.t('errors.no_report_type', scope: i18n_scope)
        end

        if report_class.blank?
          raise OrderManagement::Errors::ReportNotFound,
                I18n.t('errors.report_not_found', scope: i18n_scope)
        end

        return if ransack_params.present?

        raise OrderManagement::Errors::MissingQueryParams,
              I18n.t('errors.missing_ransack_params', scope: i18n_scope)
      end

      def render_report
        render json: @report.as_hashes
      end

      def render_error(error)
        render json: { error: error.message }, status: :unprocessable_entity
      end
    end
  end
end
