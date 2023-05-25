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
end
