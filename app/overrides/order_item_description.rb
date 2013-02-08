Deface::Override.new(:virtual_path  => "spree/shared/_order_details",
                     :replace       => "[data-hook='order_item_description']",
                     :partial       => "spree/orders/order_item_description",
                     :name          => "order_item_description",
                     :original      => '1729abc5f441607b09cc0d44843a8dfd660ac5e0')