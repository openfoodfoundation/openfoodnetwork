Deface::Override.new(:virtual_path  => "spree/products/show",
                     :insert_before => "[data-hook='cart_form']",
                     :partial       => "spree/products/distributor_details",
                     :name          => "add_distributor_details_to_product",
                     :original      => '789e3f5f6f36a8cd4115d7342752a37735659298')
