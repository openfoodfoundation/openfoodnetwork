Deface::Override.new(:virtual_path  => "spree/admin/shared/_configuration_menu",
                     :name          => "add_enterprise_fees_to_admin_configurations_menu",
                     :insert_bottom => "[data-hook='admin_configurations_sidebar_menu']",
                     :partial       => 'enterprise_fees/admin_configurations_menu',
                     :original      => '29e0ab9c171ffab1988cb439b5d42300b78fe088')
