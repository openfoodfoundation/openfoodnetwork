#
# overriding spree/core/app/views/spree/admin/variants/search.rabl
#
collection @variants
attributes :sku, :options_text, :in_stock?, :on_demand, :on_hand, :id, :cost_price

node(:name) do |v|
  # TODO: when products must have a unit, full_name will always be present
  variant_specific = v.full_name
  if variant_specific.present?
    "#{v.name} - #{v.full_name}"
  else
    v.name
  end
end

node(:full_name, &:full_name)

node(:producer_name) do |v|
  v.product.supplier.name
end

node(:stock_location_id) do |v|
  v.stock_items.first.stock_location.id
end

node(:stock_location_name) do |v|
  v.stock_items.first.stock_location.name
end

child(images: :images) do
  attributes :mini_url
end

child(option_values: :option_values) do
  child(option_type: :option_type) do
    attributes :name, :presentation
  end
  attributes :name, :presentation
end
