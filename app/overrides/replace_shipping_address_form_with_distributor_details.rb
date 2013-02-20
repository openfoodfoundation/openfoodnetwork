Deface::Override.new(:virtual_path  => "spree/checkout/_address",
            :replace    => "[data-hook='shipping_fieldset_wrapper']",
            :partial    => "spree/checkout/distributor",
            :name       => "replace_shipping_address_form_with_distributor_details",
            :original   => '53e219f90a2e1ba702a767261d0c2afe100ac751')
