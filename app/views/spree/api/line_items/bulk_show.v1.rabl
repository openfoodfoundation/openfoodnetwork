object @line_item
attributes :id, :quantity, :max_quantity
node( :supplier ) { |li| partial 'api/enterprises/bulk_show', :object => li.product.supplier }
node( :units_product ) { |li| partial 'spree/api/products/units_show', :object => li.product }
node( :units_variant ) { |li| partial 'spree/api/variants/units_show', :object => li.variant }