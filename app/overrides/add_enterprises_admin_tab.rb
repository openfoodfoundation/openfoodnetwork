Deface::Override.new(:virtual_path => "spree/layouts/admin",
                     :name => "add_enterprises_admin_tab",
                     :insert_bottom => "[data-hook='admin_tabs'], #admin_tabs[data-hook]",
                     :text => "<%= tab :enterprises, :url => main_app.admin_enterprises_path %>",
                     :original => '82e51ad38c8538eca88b683d6d874d8fdb5b5032')