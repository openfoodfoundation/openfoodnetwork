Deface::Override.new(:virtual_path => "spree/layouts/admin",
                     :name => "enterprises_admin_tabs",
                     :insert_bottom => "[data-hook='admin_tabs'], #admin_tabs[data-hook]",
                     :text => "<%= tab(:enterprises, :url => main_app.admin_enterprises_path) %>")
