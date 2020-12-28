module Spree
  module Admin
    class ReturnAuthorizationsController < ::Admin::ResourceController
      belongs_to 'spree/order', find_by: :number

      update.after :associate_inventory_units
      create.after :associate_inventory_units

      def fire
        @return_authorization.public_send("#{params[:e]}!")
        flash[:success] = Spree.t(:return_authorization_updated)
        redirect_to :back
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
