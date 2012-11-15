Deface::Override.new(:virtual_path => "spree/admin/configurations/index",
                     :name => "add_enterprise_fees_to_admin_configurations_menu",
                     :insert_bottom => "[data-hook='admin_configurations_menu']",
                     :partial => 'enterprise_fees/admin_configurations_menu')
