Deface::Override.new(:virtual_path  => "spree/layouts/admin",
                     :insert_bottom => "[data-hook='admin_inside_head']",
                     :partial       => "layouts/auth_token_script",
                     :name          => "set_auth_token_in_backend",
                     :original      => '6bc2c5de1c8f7542d033548557437c9fe4b3ba02')
