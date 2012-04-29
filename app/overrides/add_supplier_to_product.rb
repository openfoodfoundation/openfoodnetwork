Deface::Override.new(:virtual_path  => "spree/admin/products/_form",
            :insert_top  => "[data-hook='admin_product_form_right']",
            :partial       => "spree/admin/products/supplier",
            :name          => "supplier")

Deface::Override.new(:virtual_path  => "spree/admin/products/new",
            :insert_bottom  => ".left",
            :partial       => "spree/admin/products/supplier",
            :name          => "supplier")