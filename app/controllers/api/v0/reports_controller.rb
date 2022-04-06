# frozen_string_literal: true

module Api
  module V0
    class ReportsController < Api::V0::BaseController
      include ReportsActions

      rescue_from ::Reporting::Errors::Base, with: :render_error

      before_action :validate_report, :authorize_report, :validate_query

      def show
        params[:report_format] = 'json'
        @report = report_class.new(current_api_user, params)

        render_report
      end

      private

      def render_report
        render json: { data: @report.as_json }
      end

      def render_error(error)
        render json: { error: error.message }, status: :unprocessable_entity
      end

      def validate_report
        raise ::Reporting::Errors::NoReportType if report_type.blank?
        raise ::Reporting::Errors::ReportNotFound if report_class.blank?
      end

      def validate_query
        raise ::Reporting::Errors::MissingQueryParams if ransack_params.blank?
      end
    end
  end
end
