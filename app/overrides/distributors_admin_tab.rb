Deface::Override.new(:virtual_path => "spree/layouts/admin",
                     :name => "distributors_admin_tabs",
                     :insert_bottom => "[data-hook='admin_tabs'], #admin_tabs[data-hook]",
                     :text => "<%= tab(:distributors, :url => spree.admin_distributors_path) %>",
                     :disabled => false)
