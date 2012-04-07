Deface::Override.new(:virtual_path  => "spree/checkout/_delivery",
            :insert_before => "[data-hook='buttons']",
            :text          => "<p>TODO: Select a drop off point.... </p>",
            :name          => "drop_off_point")