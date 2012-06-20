# In sidebar, always render both taxonomies and filters

Deface::Override.new(:virtual_path => "spree/home/index",
                     :replace      => "[data-hook='homepage_sidebar_navigation']",
                     :partial      => 'spree/sidebar',
                     :name         => 'sidebar')

Deface::Override.new(:virtual_path => "spree/products/index",
                     :replace      => "[data-hook='homepage_sidebar_navigation']",
                     :partial      => 'spree/sidebar',
                     :name         => 'sidebar')

Deface::Override.new(:virtual_path => "spree/taxons/show",
                     :replace      => "[data-hook='taxon_sidebar_navigation']",
                     :partial      => 'spree/sidebar',
                     :name         => 'sidebar')
