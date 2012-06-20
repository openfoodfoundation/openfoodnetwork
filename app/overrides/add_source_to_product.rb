Deface::Override.new(:virtual_path  => "spree/products/show",
                     :insert_bottom => "[data-hook='product_left_part_wrap']",
                     :partial       => "spree/products/source",
                     :name          => "product_source")
