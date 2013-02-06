Deface::Override.new(:virtual_path => "spree/layouts/admin",
                     :name => "add_cms_admin_tab",
                     :insert_bottom => "[data-hook='admin_tabs'], #admin_tabs[data-hook]",
                     :text => "<%= tab 'CMS Admin', :url => main_app.cms_admin_path %>",
                     :original => '6999548b86c700f2cc5d4f9d297c94b3617fd981')