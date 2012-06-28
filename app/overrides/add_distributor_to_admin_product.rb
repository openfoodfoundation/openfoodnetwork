Deface::Override.new(:virtual_path  => "spree/admin/products/_form",
                     :insert_bottom  => "[data-hook='admin_product_form_additional_fields']",
                     :partial       => "spree/admin/products/distributors",
                     :name          => "distributors")

Deface::Override.new(:virtual_path  => "spree/admin/products/new",
                     :insert_bottom  => ".left",
                     :partial       => "spree/admin/products/distributors",
                     :name          => "distributors")
