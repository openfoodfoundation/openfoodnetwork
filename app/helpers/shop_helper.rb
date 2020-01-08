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

  def base_shop_tabs(column_sizes)
    [
      { name: 'about', cols: column_sizes[0],
        title: t(:shopping_tabs_about, distributor: current_distributor.name) },
      { name: 'producers', cols: column_sizes[1],
        title: t(:label_producers) },
      { name: 'contact', cols: column_sizes[2],
        title: t(:shopping_tabs_contact) }
    ]
  end

  def tabs_with_groups
    tabs = base_shop_tabs([6, 2, 2])
    tabs << { name: 'groups', title: t(:label_groups), cols: 2 }
  end

  def tabs_without_groups
    base_shop_tabs([4, 4, 4])
  end

  def shop_tabs
    current_distributor.groups.present? ? tabs_with_groups : tabs_without_groups
  end
end
