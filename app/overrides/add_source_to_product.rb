Deface::Override.new(:virtual_path  => "spree/products/show",
                     :insert_bottom => "[data-hook='product_left_part_wrap']",
                     :partial       => "spree/products/source",
                     :name          => "add_source_to_product",
                     :original      => 'bce3ba4847b3eac8ae061774a664ac4951d3d9db')
