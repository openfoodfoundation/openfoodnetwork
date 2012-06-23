Deface::Override.new(:virtual_path => "spree/home/index",
                     :replace      => "[data-hook='homepage_products']",
                     :partial      => "spree/shared/products_by_distributor",
                     :name         => "products")
