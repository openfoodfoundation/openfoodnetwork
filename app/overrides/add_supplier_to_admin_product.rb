Deface::Override.new(:virtual_path => "spree/admin/products/_form",
                     :insert_top   => "[data-hook='admin_product_form_right']",
                     :partial      => "spree/admin/products/supplier_form",
                     :name         => "supplier")

Deface::Override.new(:virtual_path  => "spree/admin/products/new",
                     :insert_bottom => ".right",
                     :partial       => "spree/admin/products/supplier_form",
                     :name          => "supplier")
