Deface::Override.new(:virtual_path  => "spree/checkout/_address",
            :replace    => "[data-hook='shipping_fieldset_wrapper']",
            :partial    => "spree/checkout/distributor",
            :name       => "replace_shipping_form")

Deface::Override.new(:virtual_path  => "spree/checkout/edit",
            :insert_after   => "[data-hook='checkout_summary_box']",
            :partial        => "spree/checkout/other_available_distributors",
            :name           => "other_available_distributors")
