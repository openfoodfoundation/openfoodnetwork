# frozen_string_literal: true

module Spree
  module Admin
    class ReturnAuthorizationsController < ::Admin::ResourceController
      belongs_to 'spree/order', find_by: :number

      after_action :associate_inventory_units, only: [:create, :update]

      def fire
        @return_authorization.public_send("#{params[:e]}!")
        flash[:success] = Spree.t(:return_authorization_updated)
        redirect_back fallback_location: spree.admin_dashboard_path
      end

      protected

      def associate_inventory_units
        (params[:return_quantity] || []).each do |variant_id, qty|
          @return_authorization.add_variant(variant_id.to_i, qty.to_i)
        end
      end

      def permitted_resource_params
        params.require(:return_authorization).
          permit(:amount, :reason, :stock_location_id)
      end
    end
  end
end
