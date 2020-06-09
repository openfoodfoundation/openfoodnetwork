# frozen_string_literal: true

module Reporting
  class Report
    delegate :as_hashes, :as_arrays, :table_headers, :table_rows,
             :to_csv, :to_xlsx, :to_ods, :to_json, to: :report_renderer

    attr_reader :options

    def initialize(current_user, ransack_params, options = {})
      @current_user = current_user
      @ransack_params = ransack_params.with_indifferent_access
      @options = ( options || {} ).with_indifferent_access
      @report_rows = []

      build_report
    end

    def headers
      @report_rows.first.andand.keys || []
    end

    # Implement the template methods below to create a custom report.

    def collection; end

    def report_row(object)
      {}
    end

    def ordering
      []
    end

    def summary_group
      nil
    end

    def summary_row
      []
    end

    def hide_columns
      []
    end

    private

    attr_reader :current_user, :ransack_params

    def build_report
      @report_rows = ReportBuilder.new(@report_rows, self).call
    end

    def report_renderer
      @report_renderer ||= ReportRenderer.new(@report_rows, self)
    end
  end
end
