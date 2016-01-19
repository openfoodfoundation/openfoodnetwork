Deface::Override.new(:virtual_path  => "spree/layouts/spree_application",
                     :insert_bottom => "[data-hook='inside_head']",
                     :partial       => "layouts/auth_token_script",
                     :name          => "set_auth_token_in_frontend",
                     :original      => '5659ac7dbf6ac6469907b005b85285b894677815')
