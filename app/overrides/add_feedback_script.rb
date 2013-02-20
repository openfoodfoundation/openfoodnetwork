Deface::Override.new(:virtual_path  => "spree/layouts/spree_application",
                     :insert_bottom => "[data-hook='inside_head']",
                     :partial       => "layouts/feedback_script",
                     :name          => "add_feedback_script",
                     :original      => '429dfd9824ee588f51fb1b69013933424f149592')