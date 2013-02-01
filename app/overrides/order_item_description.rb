Deface::Override.new(:virtual_path  => "spree/shared/_order_details",
                     :replace       => "[data-hook='order_item_description']",
                     :partial       => "spree/orders/order_item_description",
                     :name          => "order_item_description")