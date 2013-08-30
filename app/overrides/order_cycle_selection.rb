Deface::Override.new(:virtual_path  => "spree/home/index",
                     :insert_before => "[data-hook='homepage_products']",
                     :partial       => "order_cycles/selection",
                     :name          => "order_cycle_selection_home")

Deface::Override.new(:virtual_path  => "spree/products/index",
                     :insert_before => "[data-hook='homepage_products']",
                     :partial       => "order_cycles/selection",
                     :name          => "order_cycle_selection_products")

Deface::Override.new(:virtual_path  => "spree/taxons/show",
                     :insert_top    => "[data-hook='homepage_products']",
                     :partial       => "order_cycles/selection",
                     :name          => "order_cycle_selection_taxon")
