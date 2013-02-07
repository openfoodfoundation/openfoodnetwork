Deface::Override.new(:virtual_path => "spree/layouts/admin",
                     :name => "add_enterprises_admin_tab",
                     :insert_bottom => "[data-hook='admin_tabs'], #admin_tabs[data-hook]",
                     :text => "<%= tab :enterprises, :url => main_app.admin_enterprises_path %>",
                     :original => '6999548b86c700f2cc5d4f9d297c94b3617fd981')