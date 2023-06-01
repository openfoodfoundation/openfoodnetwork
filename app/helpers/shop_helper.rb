# frozen_string_literal: true

module ShopHelper
  def oc_select_options
    @order_cycles.map { |oc| { time: pickup_time(oc), id: oc.id } }
  end

  def require_customer?
    @require_customer ||= current_distributor.require_login? && !user_is_related_to_distributor?
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
      { name: 'home', title: t(:shopping_tabs_home), show: show_home_tab?,
        default: show_home_tab? },
      { name: 'shop', title: t(:shopping_tabs_shop), show: !require_customer?,
        default: !show_home_tab? },
      { name: 'about', title: t(:shopping_tabs_about), show: true },
      { name: 'producers', title: t(:shopping_tabs_producers), show: true },
      { name: 'contact', title: t(:shopping_tabs_contact), show: true },
      { name: 'groups', title: t(:shopping_tabs_groups), show: show_groups_tabs? },
      custom_tab,
    ].select{ |tab| tab[:show] }
  end

  def custom_tab
    {
      name: "custom_#{current_distributor.custom_tab&.title&.parameterize}",
      title: current_distributor.custom_tab&.title,
      show: current_distributor.custom_tab.present?,
      custom: true,
    }
  end

  def shop_tab_names
    shop_tabs.map { |tab| tab[:name] }
  end

  def show_home_tab?
    require_customer? || current_distributor.preferred_shopfront_message.present?
  end

  def shopfront_closed_message?
    no_open_order_cycles? && current_distributor.preferred_shopfront_closed_message.present?
  end

  def no_open_order_cycles?
    @no_open_order_cycles ||= @order_cycles&.empty?
  end

  def show_shopping_cta?
    return false if current_page?(main_app.shops_path) && current_distributor.blank?

    return false if current_distributor.present? &&
                    current_page?(main_app.enterprise_shop_path(current_distributor))

    true
  end

  private

  def show_groups_tabs?
    !current_distributor.hide_groups_tab? && current_distributor.groups.any?
  end
end
