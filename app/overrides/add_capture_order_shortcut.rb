Deface::Override.new(:virtual_path    => "spree/admin/orders/index",
                      :name           => "add_capture_order_shortcut",
                      :insert_bottom  => "[data-hook='admin_orders_index_row_actions']",
                      :partial        => 'spree/admin/orders/capture'
                      )

#Resize columns to fit new button (note: this may break with a new version of spree)
Deface::Override.new(:virtual_path    => "spree/admin/orders/index",
                      :name           => "add_capture_order_shortcut_first_column",
                      :set_attributes => "#listing_orders colgroup col:first-child",
                      :attributes     => {:style => "width: 12%"} #was 16%
                      )
Deface::Override.new(:virtual_path    => "spree/admin/orders/index",
                      :name           => "add_capture_order_shortcut_last_column",
                      :set_attributes => "#listing_orders colgroup col:last-child",
                      :attributes     => {:style => "width: 12%"} #was 8%
                      )
#And align actions column (not spree standard, but looks better IMO)
Deface::Override.new(:virtual_path    => "spree/admin/orders/index",
                      :name           => "add_capture_order_shortcut_align",
                      :set_attributes => "[data-hook='admin_orders_index_row_actions']",
                      :attributes     => {:class => "actions", :style => "text-align:left;"} #removes 'align-center' class
                      )
