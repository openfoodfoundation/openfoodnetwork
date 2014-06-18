module Spree
  module Admin
    ShippingMethodsController.class_eval do
      before_filter :do_not_destroy_referenced_shipping_methods, :only => :destroy
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

      # This method was originally written because ProductDistributions referenced shipping
      # methods, and deleting a referenced shipping method would break all the reports that
      # queried it.
      # This has changed, and now all we're protecting is Orders, which is a spree resource.
      # Do we really need to protect it ourselves? Does spree do this, or provide some means
      # of preserving the shipping method information for past orders?
      def do_not_destroy_referenced_shipping_methods
        order = Order.where(:shipping_method_id => @object).first
        if order
          flash[:error] = "That shipping method cannot be deleted as it is referenced by an order: #{order.number}."
          redirect_to collection_url and return
        end
      end

      private
      def load_hubs
        @hubs = Enterprise.managed_by(spree_current_user).is_distributor.sort_by!{ |d| [(@shipping_method.has_distributor? d) ? 0 : 1, d.name] }
      end
    end
  end
end
