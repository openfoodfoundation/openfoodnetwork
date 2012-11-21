Deface::Override.new(:virtual_path  => "spree/checkout/_delivery",
                     :insert_before => "fieldset#shipping_method",
                     :text          => "<%= cms_page_content(:content, Cms::Page.find_by_full_path('/delivery')) %>",
                     :name          => "cms_checkout_distribution")