collection @collection

attributes :id, :name

child supplied_products: :supplied_products do |product|
  attributes :name
  node(:supplier_name) { |p| p.supplier.andand.name }
  node(:image_url) { |p| p.images.present? ? p.images.first.attachment.url(:mini) : nil }
  node(:master_id) { |p| p.master.id }
  child variants: :variants do |variant|
    attributes :id
    node(:label) { |v| v.options_text }
  end
end
