require "open_food_network/reports"
require "order_management/reports/enterprise_fee_summary/parameters"
require "order_management/reports/enterprise_fee_summary/permissions"
require "order_management/reports/enterprise_fee_summary/authorizer"
require "order_management/reports/enterprise_fee_summary/report_service"
require "order_management/reports/enterprise_fee_summary/renderers/csv_renderer"
require "order_management/reports/enterprise_fee_summary/renderers/html_renderer"

module Spree
  module Admin
    module Reports
      class EnterpriseFeeSummaryReportController < BaseController
        before_filter :load_report_parameters, only: [:index]
        before_filter :load_permissions, only: [:index]
        before_filter :load_authorizer, only: [:index]

        def index
          return render_report_form if params[:report].blank?
          return respond_to_invalid_parameters unless @report_parameters.valid?

          @authorizer.authorize!
          @report = report_klass::ReportService.new(@report_parameters, report_renderer_klass)

          render_report
        rescue OpenFoodNetwork::Reports::Authorizer::ParameterNotAllowedError => e
          flash[:error] = e.message
          render_report_form
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

        def load_report_parameters
          @report_parameters = report_klass::Parameters.new(params[:report] || {})
        end

        def load_permissions
          @permissions = report_klass::Permissions.new(spree_current_user)
        end

        def load_authorizer
          @authorizer = report_klass::Authorizer.new(@report_parameters, @permissions)
        end

        def render_report
          return render_html_report unless @report.renderer.independent_file?
          send_data(@report.render, filename: @report.filename)
        end

        def render_html_report
          render action: :index
        end

        def report_renderer_klass
          case params[:report_format]
          when "csv"
            report_klass::Renderers::CsvRenderer
          when nil, "", "html"
            report_klass::Renderers::HtmlRenderer
          else
            raise OpenFoodNetwork::Reports::UnsupportedReportFormatException
          end
        end
      end
    end
  end
end
