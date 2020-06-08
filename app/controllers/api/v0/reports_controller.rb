# frozen_string_literal: true

module Api
  module V0
    class ReportsController < Api::V0::BaseController
      include ReportsActions

      rescue_from Reports::Errors::Base, with: :render_error

      before_action :validate_report, :authorize_report, :validate_query

      def show
        @report = report_class.new(current_api_user, ransack_params, report_options)

        render_report
      end

      private

      def render_report
        render json: @report.as_hashes
      end

      def render_error(error)
        render json: { error: error.message }, status: :unprocessable_entity
      end

      def validate_report
        raise Reports::Errors::NoReportType if report_type.blank?
        raise Reports::Errors::ReportNotFound if report_class.blank?
      end

      def validate_query
        raise Reports::Errors::MissingQueryParams if ransack_params.blank?
      end
    end
  end
end
