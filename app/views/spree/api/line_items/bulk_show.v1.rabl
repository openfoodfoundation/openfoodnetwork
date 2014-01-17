object @line_item
attributes :id, :quantity, :max_quantity
node( :supplier ) { |li| partial 'spree/api/enterprises/bulk_show', :object => li.product.supplier }
node( :variant_unit_text ) { |li| li.product.name }