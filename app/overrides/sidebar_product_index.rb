# In sidebar, always render both taxonomies and filters

Deface::Override.new(:virtual_path  => "spree/products/index",
                     :replace       => "[data-hook='homepage_sidebar_navigation']",
                     :partial       => 'spree/sidebar',
                     :name          => 'sidebar_product_index',
                     :original      => 'd9d1b3d18721e1c68eeaac898ca006bf8afb176c')