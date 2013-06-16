class Spree::ProductSet < ModelSet
  def initialize(attributes={})
    product_ids = attributes[:collection_attributes].each_value.map{ |p| p["id"] } if attributes[:collection_attributes]
    super(Spree::Product, (product_ids ? Spree::Product.select{ |p| p.id.in? product_ids } : Spree::Product.all ),
          proc { |attrs| attrs[:product_id].blank? },
          attributes)
  end

  # A separate method of updating products was required due to an issue with the way Rails' assign_attributes and updates_attributes behave when delegated attributes of a nested
  # object are updated via the parent object (ie. price of variants). Updating such attributes by themselves did not work using:
  # product.update_attributes( { variants_attributes: [ { id: y, price: xx.x } ] } )
  # and so an explicit call to update attributes on each individual variant was required. ie:
  # variant.update_attributes( { price: xx.x } )
  def update_attributes(attributes)
    e = @collection.detect { |e| e.id.to_s == attributes[:id].to_s && !e.id.nil? }
    if e.nil?
      @klass.new(attributes).save unless @reject_if.andand.call(attributes)
    else
      e.update_attributes(attributes.except(:id,:variants_attributes)) and (attributes[:variants_attributes] ? update_variants_attributes(e,attributes[:variants_attributes]) : true )
    end
  end

  def update_variants_attributes(product,variants_attributes)
    variants_attributes.each do |attributes|
      e = product.variants.detect { |e| e.id.to_s == attributes[:id].to_s && !e.id.nil? }
      if !e.nil?
        e.update_attributes(attributes.except(:id))
      end
    end
  end

  def save(collection_hash)
    collection_hash.each_value.all? do |product_attributes|
      update_attributes(product_attributes)
    end
  end
end