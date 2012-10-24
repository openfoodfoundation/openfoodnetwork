Deface::Override.new(:virtual_path  => "spree/layouts/spree_application",
                     :insert_bottom => "[data-hook='inside_head']",
                     :partial       => "layouts/feedback_script",
                     :name          => "feedback_script")