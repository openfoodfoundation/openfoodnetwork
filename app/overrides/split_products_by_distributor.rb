Deface::Override.new(:virtual_path => "spree/home/index",
                     :replace      => "[data-hook='homepage_products']",
                     :partial      => "spree/shared/products_by_distributor",
                     :name         => "products_home")

Deface::Override.new(:virtual_path => "spree/products/index",
                     :replace      => "[data-hook='homepage_products']",
                     :partial      => "spree/shared/products_by_distributor",
                     :name         => "products_products")

Deface::Override.new(:virtual_path => "spree/products/index",
                     :replace      => "[data-hook='search_results']",
                     :partial      => "spree/shared/products_by_distributor",
                     :name         => "products_search")

Deface::Override.new(:virtual_path => "spree/taxons/show",
                     :replace      => "[data-hook='taxon_products']",
                     :partial      => "spree/shared/products_by_distributor",
                     :name         => "products_taxon")
