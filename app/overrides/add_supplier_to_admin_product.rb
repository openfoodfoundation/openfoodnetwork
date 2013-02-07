Deface::Override.new(:virtual_path => "spree/admin/products/_form",
                     :insert_top   => "[data-hook='admin_product_form_right']",
                     :partial      => "spree/admin/products/supplier_form",
                     :name         => "add_supplier_to_admin_product",
                     :original => '18bd94de3eb8bdf8b669932bf04fc59e2e85288b')