object @product
attributes :id, :name, :price, :variant_unit, :variant_unit_scale, :variant_unit_name, :on_demand

# Infinity is not a valid JSON object, but Rails encodes it anyway
node( :on_hand ) { |p| p.on_hand.to_f.finite? ? p.on_hand : "On demand" }

node( :available_on ) { |p| p.available_on.blank? ? "" : p.available_on.strftime("%F %T") }
node( :permalink_live ) { |p| p.permalink }
node( :supplier ) do |p|
	partial 'spree/api/enterprises/bulk_show', :object => p.supplier
end
node( :variants ) do |p|
	partial 'spree/api/variants/bulk_index', :object => p.variants.order('id ASC')
end
