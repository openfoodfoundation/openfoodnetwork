module Spree
  module Admin
    ShippingMethodsController.class_eval do
      before_filter :do_not_destroy_referenced_shipping_methods, :only => :destroy

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
    end
  end
end
