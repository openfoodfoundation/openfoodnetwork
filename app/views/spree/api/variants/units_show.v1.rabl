object @variant
attributes :id
node( :unit_text ) { |v| v.product.name + (v.options_text.empty? ? "" : ": " +  v.options_text) }
node( :unit_value ) { |v| v.unit_value }
node( :group_buy_unit_size ) { |v| v.product.group_buy_unit_size }
node( :variant_unit ) { |v| v.product.variant_unit }
