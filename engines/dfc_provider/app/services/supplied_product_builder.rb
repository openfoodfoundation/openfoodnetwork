# frozen_string_literal: true

class SuppliedProductBuilder < DfcBuilder
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
      spree_product_uri: id,
      spree_product_id: variant.product.id,
      image_url: variant.product&.image&.url(:product)
    )
  end

  def self.import_variant(supplied_product, host: "")
    product_id = supplied_product.spree_product_id

    uri = RDF::URI.new(supplied_product.spree_product_uri)

    if product_id.present? || uri.host == host
      if uri.length > 0 # rubocop:disable Style/ZeroLengthPredicate RDF::URI doesn't implement empty?
        variant_id = uri.path.split("/").last
        product = Spree::Variant.find(variant_id).product
      else
        product = Spree::Product.find(product_id)
      end

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

    DfcProductTypeFactory.for(taxon_dfc_id)
  end

  def self.taxon(supplied_product)
    dfc_id = supplied_product.productType.semanticId
    Spree::Taxon.find_by(dfc_id: )
  end

  private_class_method :product_type, :taxon
end
