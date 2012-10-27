Deface::Override.new(:virtual_path  => "spree/products/show",
                     :insert_before => "[data-hook='cart_form']",
                     :partial       => "distributors/details",
                     :name          => "product_distributor_details")
