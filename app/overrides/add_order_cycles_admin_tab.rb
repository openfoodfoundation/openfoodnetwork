Deface::Override.new(:virtual_path => "spree/layouts/admin",
                     :name => "cms_order_cycles_tab",
                     :insert_bottom => "[data-hook='admin_tabs'], #admin_tabs[data-hook]",
                     :text => "<li><%= link_to('Order Cycles', main_app.admin_order_cycles_path) %></li>")
