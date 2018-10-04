class Spree::ProductSet < ModelSet
  def initialize(attributes={})
    super(Spree::Product, [], attributes, proc { |attrs| attrs[:product_id].blank? })
  end

  # A separate method of updating products was required due to an issue with
  # the way Rails' assign_attributes and updates_attributes behave when
  # delegated attributes of a nested object are updated via the parent object
  # (ie. price of variants). Updating such attributes by themselves did not
  # work using:
  #
  #   product.update_attributes(variants_attributes: [{ id: y, price: xx.x }])
  #
  # and so an explicit call to update attributes on each individual variant was
  # required. ie:
  #
  #   variant.update_attributes( { price: xx.x } )
  #
  def update_attributes(attributes)
    if attributes[:taxon_ids].present?
      attributes[:taxon_ids] = attributes[:taxon_ids].split(',')
    end

    found_model = @collection.find do |model|
      model.id.to_s == attributes[:id].to_s && model.persisted?
    end

    if found_model.nil?
      @klass.new(attributes).save unless @reject_if.andand.call(attributes)
    else
      update_product_only_attributes(found_model, attributes) &&
        update_product_variants(found_model, attributes) &&
        update_product_master(found_model, attributes)
    end
  end

  def update_product_only_attributes(product, attributes)
    if attributes.except(:id, :variants_attributes, :master_attributes).present?
      product.update_attributes(
        attributes.except(:id, :variants_attributes, :master_attributes)
      )
    else
      true
    end
  end

  def update_product_variants(product, attributes)
    if attributes[:variants_attributes]
      update_variants_attributes(product, attributes[:variants_attributes])
    else
      true
    end
  end

  def update_product_master(product, attributes)
    if attributes[:master_attributes]
      update_variant(product, attributes[:master_attributes])
    else
      true
    end
  end

  def update_variants_attributes(product, variants_attributes)
    variants_attributes.each do |attributes|
      update_variant(product, attributes)
    end
  end

  def update_variant(product, variant_attributes)
    found_variant = product.variants_including_master.find do |variant|
      variant.id.to_s == variant_attributes[:id].to_s && variant.persisted?
    end

    if found_variant.present?
      found_variant.update_attributes(variant_attributes.except(:id))
    else
      product.variants.create(variant_attributes)
    end
  end

  def collection_attributes=(attributes)
    @collection = Spree::Product
      .where(id: attributes.each_value.map { |product| product[:id] })
    @collection_hash = attributes
  end

  def save
    @collection_hash.each_value.all? do |product_attributes|
      update_attributes(product_attributes)
    end
  end
end
