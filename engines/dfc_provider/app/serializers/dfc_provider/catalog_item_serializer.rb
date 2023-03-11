# frozen_string_literal: true

# Serializer used to render a DFC CatalogItem from an OFN Product
# into JSON-LD format based on DFC ontology
module DfcProvider
  class CatalogItemSerializer < BaseSerializer
    attribute :id, key: '@id'
    attribute :type, key: '@type'
    attribute :references, key: 'dfc-b:references'
    attribute :sku, key: 'dfc-b:sku'
    attribute :stock_limitation, key: 'dfc-b:stockLimitation'
    has_many :offered_through,
             serializer: DfcProvider::OfferSerializer,
             key: 'dfc-b:offeredThrough'

    def id
      dfc_provider_routes.enterprise_catalog_item_url(
        enterprise_id: object.product.supplier_id,
        id: object.id,
      )
    end

    def type
      'dfc-b:CatalogItem'
    end

    def references
      {
        '@type' => '@id',
        '@id' => reference_id
      }
    end

    def stock_limitation; end

    def offered_through
      [object]
    end

    private

    def reference_id
      dfc_provider_routes.enterprise_supplied_product_url(
        enterprise_id: object.product.supplier_id,
        id: object.id,
      )
    end
  end
end
