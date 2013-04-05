Deface::Override.new(:virtual_path => "spree/home/index",
                     :replace      => "[data-hook='homepage_products']",
                     :partial      => "spree/shared/products_by_distribution",
                     :name         => "split_products_by_distribution_on_home",
                     :original     => '589053f6f3e534b0be729081bdfc0378beb29cca')
