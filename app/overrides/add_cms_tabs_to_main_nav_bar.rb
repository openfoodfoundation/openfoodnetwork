Deface::Override.new(:virtual_path  => "spree/shared/_main_nav_bar",
                     :name          => "add_cms_tabs_to_main_nav_bar",
                     :insert_after  => "li#home-link",
                     :partial       => "spree/shared/cms_tabs",
                     :original      => '05c6495f8760e58eb68e2cce67433cf7f5299fa4')