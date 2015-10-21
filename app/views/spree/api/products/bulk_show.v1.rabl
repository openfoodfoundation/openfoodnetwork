object @product

# TODO: This is used by bulk product edit when a product is cloned.
# But the list of products is serialized by Api::Admin::ProductSerializer.
# This should probably be unified.

attributes :id, :name, :sku, :variant_unit, :variant_unit_scale, :variant_unit_name, :on_demand, :inherits_properties
attributes :on_hand, :price, :available_on, :permalink_live, :tax_category_id

# Infinity is not a valid JSON object, but Rails encodes it anyway
node( :taxon_ids ) { |p| p.taxons.map{ |t| t.id }.join(",") }
node( :on_hand ) { |p| p.on_hand.nil? ? 0 : p.on_hand.to_f.finite? ? p.on_hand : t(:on_demand) }
node( :price ) { |p| p.price.nil? ? '0.0' : p.price }

node( :available_on ) { |p| p.available_on.blank? ? "" : p.available_on.strftime("%F %T") }
node( :permalink_live ) { |p| p.permalink }
node( :producer_id ) { |p| p.supplier_id }
node( :category_id ) { |p| p.primary_taxon_id }
node( :supplier ) do |p|
  partial 'api/enterprises/bulk_show', :object => p.supplier
end
node( :variants ) do |p|
  partial 'spree/api/variants/bulk_index', :object => p.variants.reorder('spree_variants.id ASC')
end
node( :master ) do |p|
  partial 'spree/api/variants/bulk_show', :object => p.master
end
