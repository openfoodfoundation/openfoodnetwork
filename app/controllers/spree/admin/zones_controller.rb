# frozen_string_literal: true

module Spree
  module Admin
    class ZonesController < ::Admin::ResourceController
      before_action :load_data, except: [:index]

      def new
        @zone.zone_members.build
      end

      protected

      def collection
        params[:q] ||= {}
        params[:q][:s] ||= "name asc"
        @search = super.ransack(params[:q])
        @pagy, @zones = pagy(@search.result, items: Spree::Config[:orders_per_page])
        @zones
      end

      def load_data
        @countries = Country.order(:name)
        @states = State.order(:name)
        @zones = Zone.order(:name)
      end

      def permitted_resource_params
        params.require(:zone).permit(
          :name, :description, :default_tax, :kind,
          zone_members_attributes: [:id, :zoneable_id, :zoneable_type, :_destroy]
        )
      end

      def location_after_save
        edit_object_url(@zone)
      end
    end
  end
end
