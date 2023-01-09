# frozen_string_literal: true

module Admin
  class ReportsController < Spree::Admin::BaseController
    include ReportsActions
    helper ReportsHelper

    before_action :authorize_report, only: [:show]

    # Define model class for Can? permissions
    def model_class
      Admin::ReportsController
    end

    def index
      @reports = reports.select do |report_type, _description|
        can? report_type, :report
      end
    end

    def show
      @report = report_class.new(spree_current_user, params, request)

      if report_format.present?
        export_report
      else
        render_report
      end
    end

    private

    def export_report
      send_data @report.render_as(report_format), filename: report_filename
    end

    def render_report
      assign_view_data
      render "show"
    end

    def assign_view_data
      @report_type = report_type
      @report_subtypes = report_subtypes
      @report_subtype = report_subtype
      @report_title = if report_subtype
                        report_subtype_title
                      else
                        I18n.t(:name, scope: [:admin, :reports, @report_type])
                      end
      @rendering_options = rendering_options
      @table = @report.to_html if request.post?
      @data = Reporting::FrontendData.new(spree_current_user)
    end
  end
end
