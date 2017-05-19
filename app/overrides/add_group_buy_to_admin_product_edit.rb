Deface::Override.new(:virtual_path => "spree/admin/products/_form",
                     :insert_top   => "[data-hook='admin_product_form_right']",
                     :partial      => "spree/admin/products/group_buy_form",
                     :name         => "add_group_buy_to_admin_product_edit",
                     :original     => '0c0e8d714989e48ee246a8253fb2b362f108621a')
