Deface::Override.new(:virtual_path  => "spree/admin/shared/_configuration_menu",
                     :name          => "add_enterprise_groups_to_admin_configurations_menu",
                     :insert_bottom => "[data-hook='admin_configurations_sidebar_menu']",
                     :text          => "<li><%= link_to 'Enterprise Groups', main_app.admin_enterprise_groups_path %></li>",
                     :partial       => 'enterprise_groups/admin_configurations_menu',
                     :original      => '')
