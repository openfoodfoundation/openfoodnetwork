# frozen_string_literal: true

# This is the old way of managing report, by loading Models from the DB and building
# The result from those models
module Reporting
  class ReportObjectTemplate < ReportTemplate

    attr_accessor :user, :params

    def initialize(user, params = {})
      @user = user
      @params = params
    end

    def table_headers
      raise NotImplementedError
    end

    def table_rows
      raise NotImplementedError
    end

    # If the report object do not use ransack search, create a fake one just for the form_for
    # in reports/show.haml
    def search
      Ransack::Search.new(Spree::Order)
    end

    # Rules for grouping, ordering, and summary rows
    def rules
      []
    end
  end
end
