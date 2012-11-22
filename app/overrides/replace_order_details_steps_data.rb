Deface::Override.new(:virtual_path  => "spree/shared/_order_details",
                     :replace       => "div.row.steps-data",
                     :partial       => "spree/shared/order_details_steps_data",
                     :name          => "order_details_steps_data")