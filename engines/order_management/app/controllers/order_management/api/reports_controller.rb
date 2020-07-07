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
          raise OrderManagement::Errors::ReportNotFound, 'Please specify a report type'
        end

        if report_class.blank?
          raise OrderManagement::Errors::ReportNotFound, 'Report not found'
        end

        return if ransack_params.present?

        raise OrderManagement::Errors::MissingQueryParams,
              'Please supply Ransack search params in the request'
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
