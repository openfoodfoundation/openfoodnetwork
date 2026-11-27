# frozen_string_literal: true

module Api
  module V1
    class ReportsController < BaseController
      include ReportsActions
      include ReportFilterValidation

      # v1 deliberately excludes users_and_enterprises: it uses
      # enterprise_id_in/user_id_in rather than order_cycle_id/distributor_id.
      SUPPORTED_REPORT_TYPES = %w[
        packing
        customers
        order_cycle_management
        xero_invoices
        products_and_inventory
        enterprise_fee_summary
        orders_and_distributors
        orders_and_fulfillment
        sales_tax
        payments
        suppliers
        bulk_coop
        revenues_by_hub
      ].freeze

      PERMITTED_PARAMS = %i[
        controller action format token report_type report_subtype
        order_cycle_id distributor_id page per_page
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
      before_action :validate_dates

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
        return if report_type.in?(SUPPORTED_REPORT_TYPES)

        raise Reporting::Errors::ReportNotFound
      end

      def validate_report_subtype
        return if params[:report_subtype].nil?
        return if report_subtypes_codes.include?(params[:report_subtype])

        render status: :unprocessable_entity,
               json: json_api_error(I18n.t("api.invalid_report_subtype"))
      end

      def report_params
        ReportParameters.new(report_type, report_subtype, permitted_params).to_h
      end

      def reports
        @reports ||= super
      end

      def permitted_params
        @permitted_params ||= params.permit(
          *PERMITTED_PARAMS,
          q: ReportFilterValidation::DATE_QUERY_FILTERS
        )
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
        status = if error.is_a?(Reporting::Errors::ReportNotFound)
                   :not_found
                 else
                   :unprocessable_entity
                 end

        render status:, json: json_api_error(error.message)
      end
    end
  end
end
