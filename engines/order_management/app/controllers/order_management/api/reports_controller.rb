# frozen_string_literal: true

module OrderManagement
  module Api
    class ReportsController < ::Api::BaseController
      include OrderManagement::Concerns::ReportsActions
      before_action :validate_report, :authorize_report, :validate_query

      rescue_from OrderManagement::Errors::Base, with: :render_error

      def show
        @report = report_class.new(current_api_user, ransack_params, report_options)

        render_report
      end

      private

      def validate_report
        raise OrderManagement::Errors::NoReportType if report_type.blank?
        raise OrderManagement::Errors::ReportNotFound if report_class.blank?
      end

      def validate_query
        raise OrderManagement::Errors::MissingQueryParams if ransack_params.blank?
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
