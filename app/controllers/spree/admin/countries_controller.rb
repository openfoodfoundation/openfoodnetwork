# frozen_string_literal: true

module Spree
  module Admin
    class CountriesController < ::Admin::ResourceController
      protected

      def permitted_resource_params
        params.require(:country).
          permit(:name, :iso_name, :states_required)
      end

      def collection
        super.order(:name)
      end
    end
  end
end
