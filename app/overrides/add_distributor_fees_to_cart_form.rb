Deface::Override.new(:virtual_path  => "spree/orders/edit",
                     :insert_after => "#empty-cart",
                     :partial       => "spree/orders/distributor_fees",
                     :name          => "cart_distributor_fees")
