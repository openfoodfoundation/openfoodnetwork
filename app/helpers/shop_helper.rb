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
      { name: 'home', title: t(:shopping_tabs_home), show: show_home_tab? },
      { name: 'shop', title: t(:shopping_tabs_shop), show: !require_customer? },
      { name: 'about', title: t(:shopping_tabs_about), show: true },
      { name: 'producers', title: t(:label_producers), show: true },
      { name: 'contact', title: t(:shopping_tabs_contact), show: true },
      { name: 'groups', title: t(:label_groups), show: current_distributor.groups.any? },
    ]
  end

  def first_visible_tab
    shop_tabs.find{ |tab| tab[:show] }[:name]
  end

  private

  def show_home_tab?
    require_customer? || shopfront_closed_message? ||
      current_distributor.preferred_shopfront_message.present?
  end

  def shopfront_closed_message?
    @order_cycles && @order_cycles.empty? &&
      current_distributor.preferred_shopfront_closed_message.present?
  end
end
