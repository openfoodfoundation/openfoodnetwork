class Spree::ProductSet < ModelSet
  def initialize(attributes={})
    super(Spree::Product, [], attributes, proc { |attrs| attrs[:product_id].blank? })
  end

  # A separate method of updating products was required due to an issue with the way Rails' assign_attributes and updates_attributes behave when delegated attributes of a nested
  # object are updated via the parent object (ie. price of variants). Updating such attributes by themselves did not work using:
  # product.update_attributes( { variants_attributes: [ { id: y, price: xx.x } ] } )
  # and so an explicit call to update attributes on each individual variant was required. ie:
  # variant.update_attributes( { price: xx.x } )
  def update_attributes(attributes)
    attributes[:taxon_ids] = attributes[:taxon_ids].split(',')  if attributes[:taxon_ids].present?
    e = @collection.detect { |e| e.id.to_s == attributes[:id].to_s && !e.id.nil? }
    if e.nil?
      @klass.new(attributes).save unless @reject_if.andand.call(attributes)
    else
      ( attributes.except(:id, :variants_attributes, :master_attributes).present? ? e.update_attributes(attributes.except(:id, :variants_attributes, :master_attributes)) : true) and
      (attributes[:variants_attributes] ? update_variants_attributes(e, attributes[:variants_attributes]) : true ) and
      (attributes[:master_attributes] ? update_variant(e, attributes[:master_attributes]) : true )
    end
  end

  def update_variants_attributes(product, variants_attributes)
    variants_attributes.each do |attributes|
      update_variant(product, attributes)
    end
  end

  def update_variant(product, variant_attributes)
    e = product.variants_including_master.detect { |e| e.id.to_s == variant_attributes[:id].to_s && !e.id.nil? }
    if e.present?
      e.update_attributes(variant_attributes.except(:id))
    else
      product.variants.create variant_attributes
    end
  end

  def collection_attributes=(attributes)
    @collection = Spree::Product.where( :id => attributes.each_value.map{ |p| p[:id] } )
    @collection_hash = attributes
  end

  def save
    @collection_hash.each_value.all? do |product_attributes|
      update_attributes(product_attributes)
    end
  end
end
