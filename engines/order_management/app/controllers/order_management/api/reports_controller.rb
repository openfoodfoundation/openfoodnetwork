# frozen_string_literal: true

module OrderManagement
  module Api
    class ReportsController < BaseController
      skip_authorization_check # Authorization is handled via permissions

      def show
        render_missing_params && return if ransack_params.blank?

        @report = report_class.new(current_api_user, ransack_params, report_options)

        render_report
      end

      private

      def report_class
        return if report_type.blank?

        "Reports::#{report_type}#{report_subtype}".constantize
      end

      def report_type
        params[:report_type].camelize
      end

      def report_subtype
        return unless params[:report_subtype]

        "::#{params[:report_subtype].camelize}"
      end

      def render_report
        render json: @report.as_hashes
      end

      def render_missing_params
        render json: { errors: 'Please supply Ransack search params in the request' }
      end

      def ransack_params
        params[:q]
      end

      def report_options
        params[:options]
      end
    end
  end
end
