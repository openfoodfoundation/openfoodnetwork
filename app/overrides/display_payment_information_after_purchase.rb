Deface::Override.new(:virtual_path  => "spree/shared/_order_details",
                     :replace       => "div.payment-info",
                     :partial       => "spree/shared/order_details_payment_info",
                     :name          => "order_details_payment_info")
