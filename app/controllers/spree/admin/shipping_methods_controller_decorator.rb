module Spree
  module Admin
    ShippingMethodsController.class_eval do
      before_filter :load_hubs, only: [:new, :edit, :create, :update]

      # Sort shipping methods by distributor name
      # ! Code copied from Spree::Admin::ResourceController with two added lines
      def collection
        return parent.send(controller_name) if parent_data.present?

        collection = if model_class.respond_to?(:accessible_by) &&
                         !current_ability.has_block?(params[:action], model_class)

                       model_class.accessible_by(current_ability, action)

                     else
                       model_class.scoped
                     end

        collection = collection.managed_by(spree_current_user).by_name # This line added

        # This block added
        if params.key? :enterprise_id
          distributor = Enterprise.find params[:enterprise_id]
          collection = collection.for_distributor(distributor)
        end

        collection
      end

      private

      def load_hubs
        @hubs = Enterprise.managed_by(spree_current_user).is_distributor.sort_by!{ |d| [(@shipping_method.has_distributor? d) ? 0 : 1, d.name] }
      end
    end
  end
end
