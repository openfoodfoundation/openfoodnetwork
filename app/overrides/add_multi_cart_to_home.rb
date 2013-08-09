Deface::Override.new(:virtual_path  => "spree/products/index",
                     :insert_after  => "[data-hook='homepage_products']",
                     :partial       => 'spree/shared/multi_cart.html',
                     :name          => 'multi_cart_home')

Deface::Override.new(:virtual_path  => "spree/home/index",
                     :insert_after  => "[data-hook='homepage_products']",
                     :partial       => 'spree/shared/multi_cart.html',
                     :name          => 'multi_cart_products')
