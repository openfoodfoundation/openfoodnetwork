Deface::Override.new(:virtual_path => "spree/checkout/_payment",
                     :replace      => "code[erb-loud]:contains('submit_tag t(:save_and_continue)')",
                     :text         => "<%= submit_tag I18n.t(:process_my_order), :class => 'continue button primary' %>",
                     :name         => "replace_checkout_payment_button",
                     :original     => 'ce2043a01931b3bc16b045302ebb0e0bb9150b67')
