Deface::Override.new(:virtual_path => "spree/admin/orders/index",
                     :name => "add_orders_admin_sub_menu",
                     :insert_before => "code[erb-silent]:contains('content_for :table_filter_title do')",
                     :text => "<%= render :partial => 'spree/admin/shared/order_sub_menu' %>")
