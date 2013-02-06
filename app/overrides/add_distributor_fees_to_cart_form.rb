Deface::Override.new(:virtual_path  => "spree/orders/edit",
                     :insert_after  => "#empty-cart",
                     :partial       => "spree/orders/distributor_fees",
                     :name          => "add_distributor_fees_to_cart_form",
                     :original      => 'b5a751777e66ccbd45d7f1b980ecd201af94cb5b')
