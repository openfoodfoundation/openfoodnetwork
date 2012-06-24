Deface::Override.new(:virtual_path  => "spree/products/_cart_form",
                     :replace       => "[data-hook='product_price'] .add-to-cart",
                     :partial       => "spree/products/add_to_cart",
                     :name          => "product_add_to_cart")
