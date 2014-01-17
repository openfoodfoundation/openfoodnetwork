object @variant

attributes :id, :options_text, :price, :unit_value, :unit_description, :on_demand

# Infinity is not a valid JSON object, but Rails encodes it anyway
node( :on_hand ) { |p| p.on_hand.to_f.finite? ? p.on_hand : "On demand" }
