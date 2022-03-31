# frozen_string_literal: true

module Reporting
  class ReportTemplate
    include ReportsHelper
    attr_accessor :user, :params, :ransack_params

    delegate :as_json, :as_arrays, :to_csv, :to_xlsx, :to_ods, :to_pdf, :to_json, to: :renderer

    OPTIONAL_HEADERS = [].freeze

    def initialize(user, params)
      @user = user
      @params = params || {}
      @params = @params.permit!.to_h unless @params.is_a? Hash
      @ransack_params = @params[:q] || {}
    end

    def table_headers
      raise NotImplementedError
    end

    def table_rows
      raise NotImplementedError
    end

    # Message to be displayed at the top of rendered table
    def message
      ""
    end

    # Ransack search to get base ActiveRelation
    # If the report object do not use ransack search, create a fake one just for the form_for
    # in reports/show.haml
    def search
      Ransack::Search.new(Spree::Order)
    end

    private

    def renderer
      @renderer ||= ReportRenderer.new(self)
    end
  end
end
