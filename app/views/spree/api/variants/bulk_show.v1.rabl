object @variant

attributes :id, :options_text, :unit_value, :unit_description, :on_demand, :display_as, :display_name

# Infinity is not a valid JSON object, but Rails encodes it anyway
node( :on_hand ) { |v| v.on_hand.nil? ? 0 : ( v.on_hand.to_f.finite? ? v.on_hand : t(:on_demand) ) }
node( :price ) { |v| v.price.nil? ? 0.to_f : v.price }
