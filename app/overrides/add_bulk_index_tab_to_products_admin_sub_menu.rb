Deface::Override.new(:virtual_path => "spree/admin/shared/_product_sub_menu",
                     :name => "add_bulk_index_tab_to_products_admin_sub_menu",
                     :insert_bottom => "[data-hook='admin_product_sub_tabs']",
                     :text => "<%= tab('Bulk Product Edit', :url => bulk_index_admin_products_path) %>")