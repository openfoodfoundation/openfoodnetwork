# frozen_string_literal: true

class SuppliedProductBuilder < DfcBuilder
  PRODUCT_TYPES = {} # rubocop:disable Style/MutableConstant

  def self.supplied_product(variant)
    id = urls.enterprise_supplied_product_url(
      enterprise_id: variant.product.supplier_id,
      id: variant.id,
    )

    DfcProvider::SuppliedProduct.new(
      id,
      name: variant.product_and_full_name,
      description: variant.description,
      productType: product_type(variant),
      quantity: QuantitativeValueBuilder.quantity(variant),
      spree_product_id: variant.product.id,
      image_url: variant.product&.image&.url(:product)
    )
  end

  def self.import_variant(supplied_product)
    product_id = supplied_product.spree_product_id

    if product_id.present?
      product = Spree::Product.find(product_id)
      Spree::Variant.new(
        product:,
        price: 0,
      ).tap do |variant|
        apply(supplied_product, variant)
      end
    else
      product = import_product(supplied_product)
      product.ensure_standard_variant
      product.variants.first
    end
  end

  def self.import_product(supplied_product)
    Spree::Product.new(
      name: supplied_product.name,
      description: supplied_product.description,
      price: 0, # will be in DFC Offer
      primary_taxon: taxon(supplied_product)
    ).tap do |product|
      QuantitativeValueBuilder.apply(supplied_product.quantity, product)
    end
  end

  def self.apply(supplied_product, variant)
    variant.product.assign_attributes(
      description: supplied_product.description,
      primary_taxon: taxon(supplied_product)
    )

    variant.display_name = supplied_product.name
    QuantitativeValueBuilder.apply(supplied_product.quantity, variant.product)
    variant.unit_value = variant.product.unit_value
  end

  def self.product_type(variant)
    taxon_dfc_id = variant.product.primary_taxon&.dfc_id

    return nil if taxon_dfc_id.nil?

    populate_product_types if PRODUCT_TYPES.empty?

    return nil if PRODUCT_TYPES[taxon_dfc_id].nil?

    call_dfc_product_type(PRODUCT_TYPES[taxon_dfc_id])
  end

  def self.populate_product_types
    DfcLoader.connector.PRODUCT_TYPES.topConcepts.each do |product_type|
      stack = []
      record_type(stack, product_type.to_s)
    end
  end

  def self.record_type(stack, product_type)
    name = product_type.to_s
    current_stack = stack.dup.push(name)

    type = call_dfc_product_type(current_stack)

    id = type.semanticId
    PRODUCT_TYPES[id] = current_stack

    # Narrower product types are defined as class method on the current product type object
    narrowers = type.methods(false).sort

    # Leaf node
    return if narrowers.empty?

    narrowers.each do |narrower|
      # recursive call
      record_type(current_stack, narrower)
    end
  end

  # Callproduct type method ie: DfcLoader.connector.PRODUCT_TYPES.DRINK.SOFT_DRINK
  def self.call_dfc_product_type(product_type_path)
    type = DfcLoader.connector.PRODUCT_TYPES
    product_type_path.each do |pt|
      type = type.public_send(pt)
    end

    type
  end

  def self.taxon(supplied_product)
    # We use english locale, might need to make this configurable
    dfc_id = supplied_product.productType.prefLabels[:en].downcase
    taxon = Spree::Taxon.find_by(dfc_id: )

    return taxon if taxon.present?

    nil
  end

  private_class_method :product_type, :populate_product_types, :record_type, :call_dfc_product_type,
                       :taxon
end
