Deface::Override.new(:virtual_path => "spree/taxons/show",
                     :replace      => "[data-hook='taxon_products']",
                     :partial      => "spree/shared/products_by_distribution",
                     :name         => "split_products_by_distribution_on_taxons_show",
                     :original     => '27b6ecd3954022246568b3ddf5e80462aa511ece')
