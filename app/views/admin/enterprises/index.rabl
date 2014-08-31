collection @collection

attributes :id, :name

node(:supplied_products) do |enterprise|
  enterprise.supplied_products.not_deleted.map do |product|
    partial 'admin/enterprises/supplied_product', object: product
  end
end
