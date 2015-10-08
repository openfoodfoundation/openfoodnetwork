#
# overriding spree/core/app/views/spree/admin/variants/search.rabl
#
collection @variants
attributes :sku, :options_text, :count_on_hand, :id, :cost_price

node(:name) do |v|
  # TODO: when products must have a unit, full_name will always be present
  variant_specific = v.full_name
  if variant_specific.present?
    "#{v.name} - #{v.full_name}"
  else
    v.name
  end
end

node(:full_name) do |v|
  v.full_name
end

node(:producer_name) do |v|
  v.product.supplier.name
end

child(:images => :images) do
  attributes :mini_url
end

child(:option_values => :option_values) do
  child(:option_type => :option_type) do
    attributes :name, :presentation
  end
  attributes :name, :presentation
end
