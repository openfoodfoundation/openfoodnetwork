# frozen_string_literal: true

class DfcBuilder
  def self.catalog_item(variant)
    id = urls.enterprise_catalog_item_url(
      enterprise_id: variant.product.supplier_id,
      id: variant.id,
    )
    product = supplied_product(variant)

    DataFoodConsortium::Connector::CatalogItem.new(
      id, product: product,
          sku: variant.sku,
          offers: [offer(variant)],
    )
  end

  def self.supplied_product(variant)
    id = urls.enterprise_supplied_product_url(
      enterprise_id: variant.product.supplier_id,
      id: variant.id,
    )

    DataFoodConsortium::Connector::SuppliedProduct.new(
      id, name: variant.name, description: variant.description
    )
  end

  def self.offer(variant)
    # We don't have an endpoint for offers yet and this URL is only a
    # placeholder for now. The offer is actually affected by order cycle and
    # customer tags. We'll solve that at a later stage.
    enterprise_url = urls.enterprise_url(id: variant.product.supplier_id)
    id = "#{enterprise_url}/offers/#{variant.id}"
    offered_to = []

    # The DFC sees "empty" stock as unlimited.
    # http://static.datafoodconsortium.org/conception/DFC%20-%20Business%20rules.pdf
    stock = variant.on_demand ? nil : variant.total_on_hand

    DataFoodConsortium::Connector::Offer.new(
      id, offeredTo: offered_to,
          price: variant.price.to_f,
          stockLimitation: stock,
    )
  end

  def self.urls
    DfcProvider::Engine.routes.url_helpers
  end
end
