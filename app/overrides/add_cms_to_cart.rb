Deface::Override.new(:virtual_path  => "spree/orders/edit",
                     :insert_after  => "h1",
                     :text          => "<%= cms_snippet_content(Cms::Snippet.find_by_identifier('cart')) %>",
                     :name          => "cms_to_cart")