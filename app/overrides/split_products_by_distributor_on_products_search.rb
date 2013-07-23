Deface::Override.new(:virtual_path => "spree/products/index",
                     :replace      => "[data-hook='search_results']",
                     :partial      => "spree/shared/products_by_distribution",
                     :name         => "split_products_by_distribution_on_products_search",
                     :original     => '5a764faee41bd3f2bb13b60bfeb61e63fede9fac')
