# In sidebar, always render both taxonomies and filters

Deface::Override.new(:virtual_path => "spree/taxons/show",
                     :replace      => "[data-hook='taxon_sidebar_navigation']",
                     :partial      => 'spree/sidebar',
                     :name         => 'sidebar_taxons_show',
                     :original => '697641363ffdb1fce91d8eea7cc883e983236ed2')