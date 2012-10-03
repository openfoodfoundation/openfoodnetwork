module Spree
  module Admin
    ShippingMethodsController.class_eval do
      before_filter :do_not_destroy_referenced_shipping_methods, :only => :destroy

      def do_not_destroy_referenced_shipping_methods
        order = Order.where(:shipping_method_id => @object).first
        if order
          flash[:error] = "That shipping method cannot be deleted as it is referenced by an order: #{order.number}."
          redirect_to collection_url and return
        end

        product_distribution = ProductDistribution.where(:shipping_method_id => @object).first
        if product_distribution
          p = product_distribution.product
          flash[:error] = "That shipping method cannot be deleted as it is referenced by a product distribution: #{p.id} - #{p.name}."
          redirect_to collection_url and return
        end

        line_item = LineItem.where(:shipping_method_id => @object).first
        if line_item
          flash[:error] = "That shipping method cannot be deleted as it is referenced by a line item in order: #{line_item.order.number}."
          redirect_to collection_url and return
        end
      end
    end
  end
end
