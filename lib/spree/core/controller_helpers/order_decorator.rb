Spree::Core::ControllerHelpers::Order.class_eval do
  # Override definition in spree/auth/app/controllers/spree/base_controller_decorator.rb
  # Do not attempt to merge incomplete and current orders. Instead, destroy the incomplete orders.
  def set_current_order
    if user = try_spree_current_user
      last_incomplete_order = user.last_incomplete_spree_order

      if session[:order_id].nil? && last_incomplete_order
        session[:order_id] = last_incomplete_order.id

      elsif current_order && last_incomplete_order && current_order != last_incomplete_order
        last_incomplete_order.destroy
      end
    end
  end
end
