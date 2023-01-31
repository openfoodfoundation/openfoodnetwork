# frozen_string_literal: true

module Admin
  module EnterpriseGroupsHelper
    def enterprise_group_side_menu_items
      [
        { name: 'primary_details', icon_class: "icon-user", selected: "selected" },
        { name: 'users', icon_class: "icon-user" },
        { name: 'about', icon_class: "icon-pencil" },
        { name: 'images', icon_class: "icon-picture" },
        { name: 'contact', icon_class: "icon-phone" },
        { name: 'web', icon_class: "icon-globe" },
      ]
    end
  end
end
