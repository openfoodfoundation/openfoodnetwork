Deface::Override.new(:virtual_path  => "spree/layouts/spree_application",
                     :insert_bottom => "[data-hook='inside_head']",
                     :partial       => "layouts/auth_token_script",
                     :name          => "auth_token_script")

Deface::Override.new(:virtual_path  => "spree/layouts/admin",
                     :insert_bottom => "[data-hook='admin_inside_head']",
                     :partial       => "layouts/auth_token_script",
                     :name          => "auth_token_script")
