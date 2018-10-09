require "open_food_network/reports"
require "order_management/reports/enterprise_fee_summary/parameters"
require "order_management/reports/enterprise_fee_summary/report_service"
require "order_management/reports/enterprise_fee_summary/renderers/csv_renderer"

module Spree
  module Admin
    module Reports
      class EnterpriseFeeSummaryReportController < BaseController
        def index
          return render_report_form if params[:report].blank?
          return respond_to_invalid_parameters unless report_parameters.valid?

          service = report_klass::ReportService.new(report_parameters, report_renderer_klass)
          send_data service.render, filename: service.filename
        end

        private

        def respond_to_invalid_parameters
          flash[:error] = I18n.t("invalid_filter_parameters", scope: i18n_scope)
          render_report_form
        end

        def i18n_scope
          "order_management.reports.enterprise_fee_summary"
        end

        def render_report_form
          render action: :index
        end

        def report_klass
          OrderManagement::Reports::EnterpriseFeeSummary
        end

        def report_parameters
          @report_parameters ||= report_klass::Parameters.new(params[:report])
        end

        def report_renderer_klass
          case params[:report_format]
          when "csv"
            report_klass::Renderers::CsvRenderer
          else
            raise OpenFoodNetwork::Reports::UnsupportedReportFormatException
          end
        end
      end
    end
  end
end
