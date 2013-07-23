Deface::Override.new(:virtual_path  => "spree/layouts/admin",
                     :name          => "add_order_cycles_admin_tab",
                     :insert_bottom => "[data-hook='admin_tabs'], #admin_tabs[data-hook]",
                     :text          => "<%= tab :order_cycles, :url => main_app.admin_order_cycles_path %>",
                     :original      => 'd4e321201ecb543e92192a031c8896a45dde3576')