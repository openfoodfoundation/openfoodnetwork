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
    current_distributor.require_login? and not spree_current_user.andand.customer_of current_distributor
  end
end
