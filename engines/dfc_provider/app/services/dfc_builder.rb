# frozen_string_literal: true

class DfcBuilder
  def self.catalog_item(variant, include_product: true)
    id = urls.enterprise_catalog_item_url(
      enterprise_id: variant.supplier_id,
      id: variant.id,
    )
    product = SuppliedProductBuilder.supplied_product(variant) if include_product

    DataFoodConsortium::ConnectorV1::CatalogItem.new(
      id, product:,
          sku: variant.sku,
          stockLimitation: stock_limitation(variant),
          offers: [OfferBuilder.build(variant)],
    )
  end

  def self.stock_limitation(variant)
    variant.on_demand ? nil : variant.total_on_hand
  end

  def self.urls
    DfcProvider::Engine.routes.url_helpers
  end
end
