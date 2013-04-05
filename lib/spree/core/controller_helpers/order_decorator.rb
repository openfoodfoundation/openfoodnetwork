Spree::Core::ControllerHelpers::Order.class_eval do
  # Override definition in spree/auth/app/controllers/spree/base_controller_decorator.rb
  # Do not attempt to merge incomplete and current orders when they have differing distributors
  # Instead, destroy the incomplete orders, otherwise they are restored after checkout, causing much confusion
  def set_current_order
    if user = try_spree_current_user
      last_incomplete_order = user.last_incomplete_spree_order
      if session[:order_id].nil? && last_incomplete_order
        session[:order_id] = last_incomplete_order.id
      elsif current_order && last_incomplete_order && current_order != last_incomplete_order
        if (current_order.distributor.nil? || current_order.distributor == last_incomplete_order.distributor) &&
           (current_order.order_cycle.nil? || current_order.order_cycle == last_incomplete_order.order_cycle)

          current_order.set_distributor! last_incomplete_order.distributor if current_order.distributor.nil?
          current_order.set_order_cycle! last_incomplete_order.order_cycle if current_order.order_cycle.nil?
          current_order.merge!(last_incomplete_order)
        else
          last_incomplete_order.destroy
        end
      end
    end
  end
end
