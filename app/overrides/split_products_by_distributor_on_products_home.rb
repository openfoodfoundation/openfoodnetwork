Deface::Override.new(:virtual_path => "spree/products/index",
                     :replace      => "[data-hook='homepage_products']",
                     :partial      => "spree/shared/products_by_distribution",
                     :name         => "split_products_by_distribution_on_products_home",
                     :original     => '22097416de0a5851d43c572301779de06ed84d17')
