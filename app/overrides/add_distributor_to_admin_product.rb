Deface::Override.new(:virtual_path  => "spree/admin/products/_form",
                     :insert_bottom => "[data-hook='admin_product_form_additional_fields']",
                     :partial       => "spree/admin/products/distributors_form",
                     :name          => "add_distributor_to_admin_product_edit",
                     :original      => '5a6c66358efbce3e73eb60a168ac4914a6bcc27f')
