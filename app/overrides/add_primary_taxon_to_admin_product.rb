Deface::Override.new(:virtual_path => "spree/admin/products/_form",
                     :insert_top   => "[data-hook='admin_product_form_right']",
                     :partial      => "spree/admin/products/primary_taxon_form",
                     :name         => "add_primary_taxon_to_admin_product")
