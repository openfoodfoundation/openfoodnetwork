# frozen_string_literal: true

class ProductGroupBuilder < DfcBuilder
  def self.product_group(product)
    id = urls.enterprise_product_group_url(
      enterprise_id: product.variants.first.supplier_id,
      id: product.id,
    )
    variants = product.variants.map do |spree_variant|
      SuppliedProductBuilder.semantic_id(spree_variant)
    end

    DataFoodConsortium::Connector::SuppliedProduct.new(
      id, variants:,
    )
  end
end
