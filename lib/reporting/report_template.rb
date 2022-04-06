# frozen_string_literal: true

module Reporting
  class ReportTemplate
    include ReportsHelper
    attr_accessor :user, :params, :ransack_params

    delegate :as_json, :as_arrays, :to_csv, :to_xlsx, :to_ods, :to_pdf, :to_json, to: :renderer

    def table_headers
      raise NotImplementedError
    end

    def table_rows
      raise NotImplementedError
    end

    private

    def renderer
      @renderer ||= ReportRenderer.new(self)
    end
  end
end
