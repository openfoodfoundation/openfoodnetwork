Deface::Override.new(:virtual_path  => "spree/admin/shared/_configuration_menu",
                     :name          => "add_enterprise_fees_to_admin_configurations_menu",
                     :insert_bottom => "[data-hook='admin_configurations_sidebar_menu']",
                     :text          => "<li><%= link_to I18n.t(:enterprise_fees), main_app.admin_enterprise_fees_path %></li>",
                     :partial       => 'enterprise_fees/admin_configurations_menu',
                     :original      => '8445a03cc903cacc832f395757ffcfaa7e99ca92')
