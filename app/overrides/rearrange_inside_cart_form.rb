# Remove column layout from cart form items so we can style it with CSS
Deface::Override.new(:virtual_path  => "spree/orders/edit",
                     :replace       => "[data-hook='inside_cart_form']",
                     :partial       => "spree/orders/inside_cart_form",
                     :name          => "rearrange_inside_cart_form",
                     :original      => 'e30b0e749869c51f004242b0cb7be582b45e044e')
