# frozen_string_literal: true

module Spree
  module Admin
    class StatesController < ::Admin::ResourceController
      belongs_to 'spree/country'
      before_action :load_data

      def index
        respond_with(@collection) do |format|
          format.html
          format.js { render partial: 'state_list' }
        end
      end

      protected

      def location_after_save
        spree.admin_country_states_url(@country)
      end

      def collection
        super.order(:name)
      end

      def load_data
        @countries = Country.order(:name)
      end

      def permitted_resource_params
        params.require(:state).permit(:name, :abbr)
      end
    end
  end
end
