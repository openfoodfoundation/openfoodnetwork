Deface::Override.new(:virtual_path  => "spree/admin/products/new",
                     :insert_after  => "[data-hook='new_product_attrs']",
                     :partial       => "spree/admin/products/distributors_form",
                     :name          => "add_distributor_to_admin_product_new",
                     :original      => '59b7ed369769267bdedb596768fcfcc2cb94f122')