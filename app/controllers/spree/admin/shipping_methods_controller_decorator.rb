module Spree
  module Admin
    ShippingMethodsController.class_eval do
      before_filter :do_not_destroy_referenced_shipping_methods, only: :destroy
      before_filter :load_hubs, only: [:new, :edit, :create, :update]

      # Sort shipping methods by distributor name
      def collection
        collection = super
        collection = collection.managed_by(spree_current_user).by_name

        if params.key? :enterprise_id
          distributor = Enterprise.find params[:enterprise_id]
          collection = collection.for_distributor(distributor)
        end

        collection
      end

      # Spree allows soft deletes of shipping_methods but our reports are not adapted to that
      #   Here we prevent the deletion (even soft) of shipping_methods that are referenced in orders
      def do_not_destroy_referenced_shipping_methods
        order = Order.joins(shipments: :shipping_rates)
          .where( spree_shipping_rates: { shipping_method_id: @object } )
          .first
        return unless order
        flash[:error] = I18n.t(:shipping_method_destroy_error, number: order.number)
        redirect_to(collection_url) && return
      end

      private

      def load_hubs
        # rubocop:disable Style/TernaryParentheses
        @hubs = Enterprise.managed_by(spree_current_user).is_distributor.sort_by! do |d|
          [(@shipping_method.has_distributor? d) ? 0 : 1, d.name]
        end
        # rubocop:enable Style/TernaryParentheses
      end
    end
  end
end
