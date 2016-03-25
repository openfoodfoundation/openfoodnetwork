module ShopHelper
  def order_cycles_name_and_pickup_times(order_cycles)
    order_cycles.map do |oc|
      [
        pickup_time(oc),
        oc.id
      ]
    end
  end

  def require_customer?
    current_distributor.require_login? && !user_is_related_to_distributor?
  end

  def user_is_related_to_distributor?
    spree_current_user.present? && (
      spree_current_user.admin? ||
      spree_current_user.enterprises.include?(current_distributor) ||
      spree_current_user.customer_of(current_distributor)
    )
  end
end
