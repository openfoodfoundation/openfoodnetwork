# Remove column layout from cart form items so we can style it with CSS
Deface::Override.new(:virtual_path  => "spree/orders/edit",
                     :replace       => "#empty-cart[data-hook]",
                     :partial       => "spree/orders/empty_cart_form",
                     :name          => "rearrange_empty_cart_form",
                     :original      => 'b5a751777e66ccbd45d7f1b980ecd201af94cb5b')