Deface::Override.new(:virtual_path  => "spree/checkout/_delivery",
                     :insert_before => "fieldset#shipping_method",
                     :text          => "<%= cms_snippet_content(Cms::Snippet.find_by_identifier('distribution')) %>",
                     :name          => "cms_checkout_distribution")