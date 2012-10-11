Deface::Override.new(:virtual_path => "spree/layouts/admin",
                     :name => "cms_admin_tab",
                     :insert_bottom => "[data-hook='admin_tabs'], #admin_tabs[data-hook]",
                     :text => "<li><%= link_to('CMS Admin', main_app.cms_admin_path) %></li>")
