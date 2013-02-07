Deface::Override.new(:virtual_path  => "spree/admin/shared/_configuration_menu",
                     :name          => "add_cms_admin_to_admin_configurations_menu",
                     :insert_bottom => "[data-hook='admin_configurations_sidebar_menu']",
                     :text          => "<li><%= link_to 'CMS Admin', main_app.cms_admin_path %></li>",
                     :partial       => 'enterprise_fees/admin_configurations_menu',
                     :original      => '29e0ab9c171ffab1988cb439b5d42300b78fe088' )
