# frozen_string_literal: true

module Api
  module V1
    class ReportsController < BaseController
      include ReportsActions

      rescue_from Reporting::Errors::Base, with: :render_report_error
      rescue_from Reporting::Reports::EnterpriseFeeSummary::ParameterNotAllowedError,
                  with: :render_forbidden_report
      rescue_from ActiveModel::ValidationError, with: :render_invalid_report

      before_action :validate_report_type
      before_action :authorize_report
      before_action :validate_report_subtype
      before_action :validate_filters

      def show
        supported_types = %w[
          packing customers order_cycle_management xero_invoices
          products_and_inventory enterprise_fee_summary orders_and_distributors
        ]
        return head :not_implemented unless report_type.in?(supported_types)

        report = report_class.new(current_api_user, report_params)

        render json: { data: report.as_json }
      end

      private

      def validate_report_type
        return if reports.key?(report_type.to_sym)

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

      def report_params
        translated = case report_type
                     when "packing"
                       packing_report_params
                     when "customers"
                       {
                         order_cycle_id: params[:order_cycle_id],
                         distributor_id: params[:distributor_id],
                         q: date_filters
                       }
                     when "products_and_inventory"
                       {
                         order_cycle_id: params[:order_cycle_id],
                         distributor_id: params[:distributor_id]
                       }
                     when "order_cycle_management"
                       order_cycle_management_report_params
                     when "xero_invoices"
                       xero_report_params
                     when "enterprise_fee_summary"
                       enterprise_fee_report_params
                     when "orders_and_distributors"
                       order_report_params
                     end

        translated.merge(
          report_format: "json",
          report_subtype:
        )
      end

      def date_filters
        params.fetch(:q, ActionController::Parameters.new).
          permit(:completed_at_gt, :completed_at_lt).to_h.symbolize_keys
      end

      def packing_report_params
        filters = {}

        if params[:order_cycle_id].present?
          filters[:order_cycle_id_in] = [params[:order_cycle_id]]
        end

        if params[:distributor_id].present?
          filters[:order_distributor_id_in] = [params[:distributor_id]]
        end

        dates = date_filters

        if dates[:completed_at_gt].present?
          filters[:order_completed_at_gt] = dates[:completed_at_gt]
        end

        if dates[:completed_at_lt].present?
          filters[:order_completed_at_lt] = dates[:completed_at_lt]
        end

        { q: filters }
      end

      def order_cycle_management_report_params
        filters = date_filters

        if params[:distributor_id].present?
          filters[:distributor_id_in] = [params[:distributor_id]]
        end

        {
          order_cycle_id: params[:order_cycle_id],
          q: filters
        }
      end

      def xero_report_params
        filters = date_filters

        if params[:order_cycle_id].present?
          filters[:order_cycle_id_eq] = params[:order_cycle_id]
        end

        if params[:distributor_id].present?
          filters[:distributor_id_eq] = params[:distributor_id]
        end

        { q: filters }
      end

      def order_report_params
        filters = date_filters

        if params[:order_cycle_id].present?
          filters[:order_cycle_id_in] = [params[:order_cycle_id]]
        end

        if params[:distributor_id].present?
          filters[:distributor_id_in] = [params[:distributor_id]]
        end

        { q: filters }
      end

      def enterprise_fee_report_params
        return order_report_params unless report_subtype == "fee_summary"

        filters = date_filters

        if params[:order_cycle_id].present?
          filters[:order_cycle_ids] = [params[:order_cycle_id]]
        end

        if params[:distributor_id].present?
          filters[:distributor_ids] = [params[:distributor_id]]
        end

        { q: filters }
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