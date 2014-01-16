Deface::Override.new(:virtual_path => "spree/admin/shared/_product_sub_menu",
                     :name => "add_bulk_edit_tab_to_products_admin_sub_menu",
                     :insert_bottom => "[data-hook='admin_product_sub_tabs']",
                     :text => "<%= tab :bulk_product_edit, :url => bulk_edit_admin_products_path, :match_path => '/products/bulk_edit' %>")
