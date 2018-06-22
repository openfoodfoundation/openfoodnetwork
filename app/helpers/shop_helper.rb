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

  def shop_tabs
    [
      { name: 'about', title: t(:shopping_tabs_about, distributor: current_distributor.name), cols: 6 },
      { name: 'producers', title: t(:label_producers), cols: 2 },
      { name: 'contact', title: t(:shopping_tabs_contact), cols: 2 },
      { name: 'groups', title: t(:label_groups), cols: 2 },
    ]
  end
end
