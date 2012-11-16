Deface::Override.new(:virtual_path  => "spree/products/show",
                     :insert_before => "[data-hook='cart_form']",
                     :partial       => "spree/products/distributor_details",
                     :name          => "product_distributor_details")

Deface::Override.new(:virtual_path  => "spree/products/show",
                     :insert_after  => "[data-hook='product_show']",
                     :text          => "<%= javascript_include_tag main_app.distributors_enterprises_path(:format => :js) %>",
                     :name          => "product_distributor_details_js")
