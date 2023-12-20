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
      productType: product_type,
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
      primary_taxon: Spree::Taxon.first, # dummy value until we have a mapping
    ).tap do |product|
      QuantitativeValueBuilder.apply(supplied_product.quantity, product)
    end
  end

  def self.apply(supplied_product, variant)
    variant.product.assign_attributes(
      name: supplied_product.name,
      description: supplied_product.description,
    )

    QuantitativeValueBuilder.apply(supplied_product.quantity, variant.product)
    variant.unit_value = variant.product.unit_value
  end
end
