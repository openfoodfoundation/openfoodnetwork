Deface::Override.new(:virtual_path => "spree/layouts/admin",
                     :name => "auth_admin_login_navigation_bar",
                     :insert_top => "[data-hook='admin_login_navigation_bar'], #admin_login_navigation_bar[data-hook]",
                     :partial => "spree/layouts/admin/login_nav",
                     :original => '841227d0aedf7909d62237d8778df99100087715')
