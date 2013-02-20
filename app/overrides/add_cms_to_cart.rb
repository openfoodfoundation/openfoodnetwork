Deface::Override.new(:virtual_path  => "spree/orders/edit",
                     :insert_after  => "h1",
                     :text          => "<%= cms_snippet_content(Cms::Snippet.find_by_identifier('cart')) %>",
                     :name          => "add_cms_to_cart",
                     :original => '206a92e6f50966b057e877321b573bc293787894')