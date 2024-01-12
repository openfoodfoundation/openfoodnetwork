# frozen_string_literal: true

class DfcBuilder
  def self.catalog_item(variant)
    id = urls.enterprise_catalog_item_url(
      enterprise_id: variant.product.supplier_id,
      id: variant.id,
    )
    product = SuppliedProductBuilder.supplied_product(variant)

    DataFoodConsortium::Connector::CatalogItem.new(
      id, product:,
          sku: variant.sku,
          stockLimitation: stock_limitation(variant),
          offers: [OfferBuilder.build(variant)],
    )
  end

  # The DFC sees "empty" stock as unlimited.
  # http://static.datafoodconsortium.org/conception/DFC%20-%20Business%20rules.pdf
  def self.stock_limitation(variant)
    variant.on_demand ? nil : variant.total_on_hand
  end

  def self.urls
    DfcProvider::Engine.routes.url_helpers
  end
end
