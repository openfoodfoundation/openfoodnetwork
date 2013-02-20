# In sidebar, always render both taxonomies and filters

Deface::Override.new(:virtual_path  => "spree/home/index",
                     :replace       => "[data-hook='homepage_sidebar_navigation']",
                     :partial       => 'spree/sidebar',
                     :name          => 'sidebar_home_index',
                     :original      => 'f5a06c5f558ec681c172ad62ddcf8f84ad0a99c4')