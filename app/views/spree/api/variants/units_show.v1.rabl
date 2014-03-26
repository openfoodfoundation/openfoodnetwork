object @variant
attributes :id
node( :unit_text ) { |v| v.product.name + (v.options_text.empty? ? "" : ": " +  v.options_text) }
node( :unit_value ) { |v| v.unit_value }
