Deface::Override.new(:virtual_path => "spree/admin/products/_form",
                     :insert_top   => "[data-hook='admin_product_form_right']",
                     :partial      => "spree/admin/products/group_buy_form",
                     :name         => "group buy")

Deface::Override.new(:virtual_path  => "spree/admin/products/new",
                     :insert_bottom => ".right",
                     :partial       => "spree/admin/products/group_buy_form",
                     :name          => "group buy")
