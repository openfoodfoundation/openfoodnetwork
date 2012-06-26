Deface::Override.new(:virtual_path  => "spree/checkout/_address",
            :replace       => "[data-hook='shipping_fieldset_wrapper']",
            :partial       => "spree/checkout/distributor",
            :name          => "delivery_address")
