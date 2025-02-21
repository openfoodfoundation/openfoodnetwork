# frozen_string_literal: true

class ProductGroupBuilder < DfcBuilder
  def self.product_group(product)
    id = urls.product_group_url(id: product.id)
    variants = product.variants.map do |spree_variant|
      SuppliedProductBuilder.semantic_id(spree_variant)
    end

    DataFoodConsortium::Connector::SuppliedProduct.new(
      id, variants:,
          name: product.name,
    )
  end

  def self.apply(supplied_product, spree_product)
    description = supplied_product.isVariantOf.first.try(:description) ||
                  supplied_product.description
    name = supplied_product.isVariantOf.first.try(:name)
    spree_product.description = description if description.present?
    spree_product.name = name if name.present?
  end
end
