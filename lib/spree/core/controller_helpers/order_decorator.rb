Spree::Core::ControllerHelpers::Order.class_eval do
  def current_order_with_scoped_variants(create_order_if_necessary = false)
    order = current_order_without_scoped_variants(create_order_if_necessary)

    if order
      scoper = OpenFoodNetwork::ScopeVariantToHub.new(order.distributor)
      order.line_items.each do |li|
        scoper.scope(li.variant)
      end
    end

    order
  end
  alias_method_chain :current_order, :scoped_variants

  def set_current_order
    if user = try_spree_current_user
      last_incomplete_order = user.last_incomplete_spree_order
      if session[:order_id].nil? && last_incomplete_order
        session[:order_id] = last_incomplete_order.id
      elsif separate_orders?(last_incomplete_order)
        if order_should_be_kept?(last_incomplete_order)
          current_order(true).merge!(last_incomplete_order)
        else
          last_incomplete_order.destroy
        end
      end
    end
  end

  private

  def separate_orders?(order)
    current_order && order && current_order != order
  end

  def order_should_be_kept?(order)
    current_order.distributor == order.distributor &&
      current_order.order_cycle == order.order_cycle &&
      current_order.line_items.empty?
  end
end
