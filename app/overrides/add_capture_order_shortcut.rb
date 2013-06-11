Deface::Override.new(:virtual_path    => "spree/admin/orders/index",
                      :name           => "add_capture_order_shortcut",
                      :insert_bottom  => "[data-hook='admin_orders_index_row_actions']",
                      #copied from backend / app / views / spree / admin / payments / _list.html.erb:
                      :text           => '<% order.payment.actions.grep(/^capture$/).each do |action| %>
                                            <%= link_to_with_icon "icon-#{action}", t(action), fire_admin_order_payment_path(order, order.payment, :e => action), :method => :put, :no_text => true, :data => {:action => action} %>
                                          <% end %>'
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
                      
