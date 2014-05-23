Deface::Override.new(:virtual_path  => "spree/admin/products/new",
                     :insert_before => "[data-hook='new_product_attrs']",
                     :partial       => "spree/admin/products/primary_taxon_form",
                     :name          => "add_primary_taxon_to_admin_product_new")
