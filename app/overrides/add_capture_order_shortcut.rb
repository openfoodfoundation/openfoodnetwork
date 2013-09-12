Deface::Override.new(:virtual_path    => "spree/admin/orders/index",
                      :name           => "add_capture_order_shortcut",
                      :insert_bottom  => "[data-hook='admin_orders_index_row_actions']",
                      :partial        => 'spree/admin/orders/capture'
                      )
# And align actions column (not spree standard, but looks better IMO)
Deface::Override.new(:virtual_path    => "spree/admin/orders/index",
                      :name           => "add_capture_order_shortcut_align",
                      :set_attributes => "[data-hook='admin_orders_index_row_actions']",
                      :attributes     => {:class => "actions", :style => "text-align:left;"} #removes 'align-center' class
                      )
