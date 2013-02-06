Deface::Override.new(:virtual_path => "spree/layouts/admin",
                     :name => "add_order_cycles_admin_tab",
                     :insert_bottom => "[data-hook='admin_tabs'], #admin_tabs[data-hook]",
                     :text => "<%= tab 'Order Cycles', :url => main_app.admin_order_cycles_path %>",
                     :original => '3ff44d141dd4998561d0ff79b9df3b185207e325')