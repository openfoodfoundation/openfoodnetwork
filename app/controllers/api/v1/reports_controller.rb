# frozen_string_literal: true

module Api
  module V1
    class ReportsController < BaseController
      include ReportsActions

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

      PERMITTED_QUERY_FILTERS = %i[completed_at_gt completed_at_lt].freeze

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

      # Generates the selected report and renders the paginated response.
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

      # Rejects report types that are not exposed by v1.
      def validate_report_type
        return if report_type.in?(SUPPORTED_REPORT_TYPES)

        raise Reporting::Errors::ReportNotFound
      end

      # Rejects unknown subtypes for the selected report.
      def validate_report_subtype
        return if params[:report_subtype].nil?
        return if report_subtypes_codes.include?(params[:report_subtype])

        render status: :unprocessable_entity,
               json: json_api_error(I18n.t("api.invalid_report_subtype"))
      end

      # Requires at least one order cycle or distributor filter.
      def validate_filters
        return if params[:order_cycle_id].present? || params[:distributor_id].present?

        render status: :unprocessable_entity,
               json: json_api_error(I18n.t("api.missing_report_filters"))
      end

      # Rejects IDs that are not positive integer strings.
      def validate_filter_ids
        valid = %i[order_cycle_id distributor_id].all? do |key|
          value = params[key]
          value.blank? || (value.is_a?(String) && value.match?(/\A[1-9]\d*\z/))
        end
        return if valid

        render status: :unprocessable_entity,
               json: json_api_error(I18n.t("api.invalid_resource"))
      end

      # Ensures supplied order cycle and distributor IDs exist.
      def validate_filter_records
        [
          [OrderCycle, params[:order_cycle_id]],
          [Enterprise, params[:distributor_id]]
        ].each do |model, id|
          next if id.blank? || model.where(id:).exists?

          raise ActiveRecord::RecordNotFound
        end
      end

      # Builds the translated parameters for the report class.
      def report_params
        ReportParameters.new(report_type, report_subtype, permitted_params).to_h
      end

      # Memoizes the report registry for the current request.
      def reports
        @reports ||= super
      end

      # Permits only the documented top-level parameters and query filters.
      def permitted_params
        @permitted_params ||= params.permit(
          *PERMITTED_PARAMS,
          q: PERMITTED_QUERY_FILTERS
        )
      end

      # Renders a forbidden response for disallowed report filters.
      def render_forbidden_report(error)
        render status: :forbidden,
               json: json_api_error(error.message)
      end

      # Renders validation errors as a 422 response.
      def render_invalid_report(error)
        render status: :unprocessable_entity,
               json: json_api_error(error.model.errors.full_messages.join(", "))
      end

      # Renders reporting errors as a 422 response.
      def render_report_error(error)
        render status: :unprocessable_entity,
               json: json_api_error(error.message)
      end
    end
  end
end
