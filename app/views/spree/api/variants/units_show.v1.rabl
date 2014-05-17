object @variant
attributes :id

node( :unit_text ) do |v|
  options_text = v.options_text
  v.product.name + (options_text.empty? ? "" : ": #{options_text}")
end

node( :unit_value ) { |v| v.unit_value }
