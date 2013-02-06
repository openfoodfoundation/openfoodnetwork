Deface::Override.new(:virtual_path  => "spree/checkout/_delivery",
                     :insert_before => "fieldset#shipping_method",
                     :text          => "<%= cms_snippet_content(Cms::Snippet.find_by_identifier('distribution')) %>",
                     :name          => "add_cms_checkout_distribution",
                     :original => '3b417788fb9a63f464fdaeb8202f483f20518f80')