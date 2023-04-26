# frozen_string_literal: true

module Admin
  class ReportsController < Spree::Admin::BaseController
    include ActiveStorage::SetCurrent
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
      @report = report_class.new(spree_current_user, params, render: render_data?)

      if params[:report_format].present?
        export_report
      else
        show_report
      end
    end

    private

    def export_report
      send_data render_report_as(report_format), filename: report_filename
    end

    def show_report
      assign_view_data
      @table = render_report_as(:html) if render_data?
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

    def render_report_as(format)
      if OpenFoodNetwork::FeatureToggle.enabled?(:background_reports, spree_current_user)
        @blob = ReportBlob.create_for_upload_later!(report_filename)
        ReportJob.perform_later(
          report_class, spree_current_user, params, format, @blob
        )
        Timeout.timeout(max_wait_time) do
          sleep 1 until @blob.content_stored?
        end

        # This result has been rendered by Rails in safe mode already.
        @blob.result.html_safe # rubocop:disable Rails/OutputSafety
      else
        @report.render_as(format)
      end
    end

    def max_wait_time
      # This value is used by rack-timeout and nginx, usually 30 seconds in
      # staging and production:
      server_timeout = ENV.fetch("RACK_TIMEOUT_SERVICE_TIMEOUT", "15").to_f

      # Zero disables the timeout:
      return 0 if server_timeout.zero?

      # We want to time out earlier than nginx:
      server_timeout - 2.seconds
    end
  end
end
