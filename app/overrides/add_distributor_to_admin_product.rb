Deface::Override.new(:virtual_path  => "spree/admin/products/_form",
                     :insert_bottom => "[data-hook='admin_product_form_additional_fields']",
                     :partial       => "spree/admin/products/distributors_form",
                     :name          => "distributors")

Deface::Override.new(:virtual_path  => "spree/admin/products/new",
                     :insert_after  => "[data-hook='new_product_attrs']",
                     :partial       => "spree/admin/products/distributors_form",
                     :name          => "distributors")
