module Api
  class ReportsController < BaseController
    skip_authorization_check # Authorization is handled via permissions

    def packing
      render_missing_params && return if ransack_params.blank?

      @report = ::Reporting::PackingReport.new(current_api_user, ransack_params, report_options)

      render_report
    end

    private

    def render_report
      render json: @report.as_hashes
    end

    def render_missing_params
      render json: { errors: 'Please supply Ransack search params in the request' }
    end

    def ransack_params
      params[:q]
    end

    def report_options
      params[:options]
    end
  end
end
