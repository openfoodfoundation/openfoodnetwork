object @product
attributes :id, :name, :price, :on_hand
node( :available_on ) { |p| p.available_on.strftime("%F %T") }
node( :permalink_live ) { |p| p.permalink }
node( :supplier ) do |p|
	partial 'spree/api/enterprises/bulk_show', :object => p.supplier
end
node( :variants ) do |p|
	partial 'spree/api/variants/bulk_index', :object => p.variants.order('id ASC')
end

