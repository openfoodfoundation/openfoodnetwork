Deface::Override.new(:virtual_path  => "spree/products/show",
                     :insert_before => "[data-hook='cart_form']",
                     :partial       => "spree/products/distributor_details",
                     :name          => "product_distributor_details")
