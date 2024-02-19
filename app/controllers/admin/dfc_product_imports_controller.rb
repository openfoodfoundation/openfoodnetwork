# frozen_string_literal: true

module Admin
  class DfcProductImportsController < Spree::Admin::BaseController

    # Define model class for `can?` permissions:
    def model_class
      self.class
    end

    def index
      # The plan:
      #
      # * Fetch DFC catalog as JSON from URL.
      # * First step: import all products for given enterprise.
      # * Second step: render table and let user decide which ones to import.
    end
  end
end
