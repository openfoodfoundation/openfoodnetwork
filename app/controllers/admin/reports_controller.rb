# frozen_string_literal: true

module Admin
  class ReportsController < Spree::Admin::BaseController
    include ReportsActions
    helper ReportsHelper
    include ActiveStorage::SetCurrent

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
      @report = report_class.new(spree_current_user, params, render: render_data?)

      if report_format.present?
        export_report
      else
        show_report
      end
    end

    private

    def export_report
      if OpenFoodNetwork::FeatureToggle.enabled?(:background_reports, spree_current_user)
        assign_view_data
        blob_or_message
        render "show"
      else
        send_data @report.render_as(report_format), filename: report_filename
      end
    end

    def show_report
      assign_view_data
      @table = @report.render_as(:html) if render_data?
      render "show"
    end

    def assign_view_data
      @report_type = report_type
      @report_subtypes = report_subtypes
      @report_subtype = report_subtype
      @report_title = report_title
      @rendering_options = rendering_options
      @data = Reporting::FrontendData.new(spree_current_user)
    end

    def render_data?
      request.post?
    end

    def blob_or_message
      Timeout.timeout(ReportsHelper::JOB_TIMEOUT) {
        blob = @report.report_from_job(report_format, spree_current_user, report_class, params)
        flash.now[:ok_to_download] = blob
      }
    rescue Errno::ENOENT
      flash.now[:ko_to_download] = I18n.t('admin.reports.errors.no_file_could_be_generated')
    rescue StandardError
      flash.now[:ko_to_download] = I18n.t('admin.reports.errors.report_generation_timed_out')
    end
  end
end
