# frozen_string_literal: true

class SuppliedProductBuilder < DfcBuilder
  def self.supplied_product(variant)
    id = urls.enterprise_supplied_product_url(
      enterprise_id: variant.product.supplier_id,
      id: variant.id,
    )

    DataFoodConsortium::Connector::SuppliedProduct.new(
      id,
      name: variant.name_to_display,
      description: variant.description,
      productType: product_type,
      quantity: QuantitativeValueBuilder.quantity(variant),
    )
  end

  def self.import(supplied_product)
    Spree::Product.new(
      name: supplied_product.name,
      description: supplied_product.description,
      price: 0, # will be in DFC Offer
      primary_taxon: Spree::Taxon.first, # dummy value until we have a mapping
      shipping_category: DefaultShippingCategory.find_or_create,
    ).tap do |product|
      QuantitativeValueBuilder.apply(supplied_product.quantity, product)
    end
  end
end
