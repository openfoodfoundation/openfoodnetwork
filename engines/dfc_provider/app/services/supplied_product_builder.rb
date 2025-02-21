# frozen_string_literal: true

class SuppliedProductBuilder < DfcBuilder
  def self.semantic_id(variant)
    urls.enterprise_supplied_product_url(
      enterprise_id: variant.supplier_id,
      id: variant.id,
    )
  end

  def self.supplied_product(variant)
    product_uri = urls.enterprise_url(
      variant.supplier_id,
      spree_product_id: variant.product_id
    )
    product_group = ProductGroupBuilder.product_group(variant.product)

    DfcProvider::SuppliedProduct.new(
      semantic_id(variant),
      name: variant.product_and_full_name,
      description: variant.description,
      productType: product_type(variant),
      quantity: QuantitativeValueBuilder.quantity(variant),
      isVariantOf: [product_group],
      spree_product_uri: product_uri,
      spree_product_id: variant.product.id,
      image_url: variant.product&.image&.url(:product)
    )
  end

  def self.product_type(variant)
    taxon_dfc_id = variant.primary_taxon&.dfc_id

    DataFoodConsortium::Connector::SKOSParser.concepts[taxon_dfc_id]
  end

  private_class_method :product_type
end
