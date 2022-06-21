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
      send_data @report.render_as(report_format, controller: self), filename: report_filename
    end

    def render_report
      assign_view_data
      render "show"
    end

    def assign_view_data
      @report_type = report_type
      @report_subtypes = report_subtypes
      @report_subtype = report_subtype

      # Initialize data
      params[:display_summary_row] = true if request.get?
      if OpenFoodNetwork::FeatureToggle.enabled?(:report_inverse_columns_logic,
                                                 spree_current_user)
        @params_fields_to_show = if request.get?
                                   @report.columns.keys
                                 else
                                   params[:fields_to_show]
                                 end
      end

      @data = Reporting::FrontendData.new(spree_current_user)
    end
  end
end
