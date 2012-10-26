Deface::Override.new(:virtual_path => "spree/checkout/_payment",
                     :replace      => "code[erb-loud]:contains('submit_tag t(:save_and_continue)')",
                     :partial      => "spree/checkout/process_my_order_button",
                     :name         => "process_my_order_button")