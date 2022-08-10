# frozen_string_literal: true

module Admin
  module EnterpriseGroupsHelper
    def enterprise_group_side_menu_items
      [
        { name: 'primary_details', label: 'primary_details', icon_class: "icon-user",
          selected: "selected" },
        { name: 'users', label: 'users', icon_class: "icon-user" },
        { name: 'about', label: 'about', icon_class: "icon-pencil" },
        { name: 'images', label: 'images', icon_class: "icon-picture" },
        { name: 'contact', label: 'admin_enterprise_groups_contact', icon_class: "icon-phone" },
        { name: 'web', label: 'admin_enterprise_groups_web', icon_class: "icon-globe" },
      ]
    end
  end
end
