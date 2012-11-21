Deface::Override.new(:virtual_path  => "spree/orders/edit",
                     :insert_after  => "h1",
                     :text          => "<%= cms_page_content(:content, Cms::Page.find_by_full_path('/cart')) %>",
                     :name          => "cms_to_cart")