object @line_item
attributes :id, :quantity, :max_quantity, :price
node( :supplier ) { |li| partial 'api/enterprises/bulk_show', :object => li.product.supplier }
node( :units_product ) { |li| partial 'spree/api/products/units_show', :object => li.product }
node( :units_variant ) { |li| partial 'spree/api/variants/units_show', :object => li.variant }
node( :unit_value ) { |li| li.unit_value.to_f }
node( :price ) { |li| li.price }
