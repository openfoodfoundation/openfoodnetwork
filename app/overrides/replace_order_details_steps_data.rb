Deface::Override.new(:virtual_path  => "spree/shared/_order_details",
                     :replace       => "div.row.steps-data",
                     :partial       => "spree/shared/order_details_steps_data",
                     :name          => "replace_order_details_steps_data",
                     :original      => '1a68aa5db3fee7f7bbb2b6b826749aeb69168cee')
