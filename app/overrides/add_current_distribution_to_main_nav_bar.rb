Deface::Override.new(:virtual_path  => "spree/shared/_main_nav_bar",
                     :name          => "add_current_distributor_to_main_nav_bar",
                     :insert_after  => "li#link-to-cart",
                     :partial       => "spree/shared/current_distribution",
                     :original      => '0d843946b3a53643c5a7da90a3a21610208db866')
