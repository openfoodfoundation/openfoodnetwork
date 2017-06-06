Deface::Override.new(:virtual_path  => "spree/products/show",
                     :insert_after  => "[data-hook='product_show']",
                     :text          => "<%= javascript_include_tag main_app.distributors_enterprises_path(:format => :js) %>",
                     :name          => "add_distributor_details_js_to_product",
                     :original      => 'b05ac497efeeebd4464f29891fd2c4a0f60c24d9')
