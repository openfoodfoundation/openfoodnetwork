# frozen_string_literal: true

module Api
  module V1
    class ReportsController < BaseController
      include ReportsActions

      SUPPORTED_REPORT_TYPES = %w[
        packing customers order_cycle_management xero_invoices
        products_and_inventory enterprise_fee_summary orders_and_distributors
        orders_and_fulfillment sales_tax payments suppliers bulk_coop
        revenues_by_hub
      ].freeze

      rescue_from Reporting::Errors::Base, with: :render_report_error
      rescue_from Reporting::Reports::EnterpriseFeeSummary::ParameterNotAllowedError,
                  with: :render_forbidden_report
      rescue_from ActiveModel::ValidationError, with: :render_invalid_report

      before_action :validate_report_type
      before_action :authorize_report
      before_action :validate_report_subtype
      before_action :validate_filters
      before_action :validate_filter_ids
      before_action :validate_filter_records

      def show
        report = report_class.new(current_api_user, report_params)
        @pagy, rows = pagy(report.as_json, **pagy_options)

        render json: {
          data: rows,
          meta: meta_options,
          links: links_options
        }
      end

      private

      def validate_report_type
        return if report_type.in?(SUPPORTED_REPORT_TYPES) &&
                  reports.key?(report_type.to_sym)

        raise Reporting::Errors::ReportNotFound
      end

      def validate_report_subtype
        return if params[:report_subtype].nil?
        return if report_subtypes_codes.include?(params[:report_subtype])

        render status: :unprocessable_entity,
               json: json_api_error(I18n.t("api.invalid_report_subtype"))
      end

      def validate_filters
        return if params[:order_cycle_id].present? || params[:distributor_id].present?

        render status: :unprocessable_entity,
               json: json_api_error(I18n.t("api.missing_report_filters"))
      end

      def validate_filter_ids
        valid = %i[order_cycle_id distributor_id].all? do |key|
          value = params[key]
          value.blank? || (value.is_a?(String) && value.match?(/\A[1-9]\d*\z/))
        end
        return if valid

        render status: :unprocessable_entity,
               json: json_api_error(I18n.t("api.invalid_resource"))
      end

      def validate_filter_records
        OrderCycle.find(params[:order_cycle_id]) if params[:order_cycle_id].present?
        Enterprise.find(params[:distributor_id]) if params[:distributor_id].present?
      end

      def report_params
        ReportParameters.new(report_type, report_subtype, params).to_h
      end

      def render_forbidden_report(error)
        render status: :forbidden,
               json: json_api_error(error.message)
      end

      def render_invalid_report(error)
        render status: :unprocessable_entity,
               json: json_api_error(error.model.errors.full_messages.join(", "))
      end

      def render_report_error(error)
        render status: :unprocessable_entity,
               json: json_api_error(error.message)
      end
    end
  end
end
