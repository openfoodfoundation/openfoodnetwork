Deface::Override.new(:virtual_path => "spree/admin/users/_form",
                     :insert_after => "[data-hook='admin_user_form_fields']",
                     :partial      => "spree/admin/users/enterprises_form",
                     :name         => "add_enterprises_to_user"
                     )

