# frozen_string_literal: true

module Admin
  module EnterprisesHelper
    def add_check_if_single(count)
      if count == 1
        { checked: true }
      else
        {}
      end
    end

    def select_only_item(producers)
      producers.size == 1 ? producers.first.id : nil
    end

    def enterprise_side_menu_items(enterprise)
      is_shop = enterprise.sells != "none"
      show_properties = !!enterprise.is_primary_producer
      show_shipping_methods = can?(:manage_shipping_methods, enterprise) && is_shop
      show_payment_methods = can?(:manage_payment_methods, enterprise) && is_shop
      show_enterprise_fees = can?(:manage_enterprise_fees,
                                  enterprise) && (is_shop || enterprise.is_primary_producer)

      build_enterprise_side_menu_items(is_shop, show_properties, show_shipping_methods,
                                       show_payment_methods, show_enterprise_fees)
    end

    private

    def build_enterprise_side_menu_items(is_shop, show_properties, show_shipping_methods,
                                         show_payment_methods, show_enterprise_fees)
      [
        { name: 'primary_details', icon_class: "icon-home", show: true, selected: 'selected' },
        { name: 'address', icon_class: "icon-map-marker", show: true },
        { name: 'contact', icon_class: "icon-phone", show: true },
        { name: 'social',  icon_class: "icon-twitter", show: true },
        { name: 'about',   icon_class: "icon-pencil", show: true, form_name: "about_us" },
        { name: 'business_details', icon_class: "icon-briefcase", show: true },
        { name: 'images', icon_class: "icon-picture", show: true },
        { name: 'properties', icon_class: "icon-tags", show: show_properties },
        { name: 'shipping_methods', icon_class: "icon-truck", show: show_shipping_methods },
        { name: 'payment_methods',  icon_class: "icon-money", show: show_payment_methods },
        { name: 'enterprise_fees',  icon_class: "icon-tasks", show: show_enterprise_fees },
        { name: 'vouchers', icon_class: "icon-ticket", show: is_shop },
        { name: 'enterprise_permissions', icon_class: "icon-plug", show: true,
          href: admin_enterprise_relationships_path },
        { name: 'inventory_settings', icon_class: "icon-list-ol", show: is_shop },
        { name: 'tag_rules', icon_class: "icon-random", show: is_shop },
        { name: 'shop_preferences', icon_class: "icon-shopping-cart", show: is_shop },
        { name: 'users', icon_class: "icon-user", show: true },
        { name: 'white_label', icon_class: "icon-leaf", show: true },
      ]
    end
  end
end
