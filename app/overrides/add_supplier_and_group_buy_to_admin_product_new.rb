Deface::Override.new(:virtual_path  => "spree/admin/products/new",
                     :insert_before => "[data-hook='new_product_attrs']",
                     :partial       => "spree/admin/products/supplier_and_group_buy_for_new",
                     :name          => "add_supplier_and_group_buy_to_admin_product_new",
                     :original      => '59b7ed369769267bdedb596768fcfcc2cb94f122')