# frozen_string_literal: true

# Serializer used to render a DFC CatalogItemt from an OFN Product
# into JSON-LD format based on DFC ontology
module DfcProvider
  class CatalogItemSerializer
    def initialize(variant)
      @variant = variant
    end

    def serialized_data
      {
        "@id" => "/catalog_items/#{@variant.id}",
        "@type" => "dfc:CatalogItem",
        "dfc:references" => {
          "@type" => "@id",
          "@id" => "/supplied_products/#{@variant.product_id}"
        },
        "dfc:sku" => @variant.sku,
        "dfc:stockLimitation" => nil,
        "dfc:offeredThrough" => serialized_offers
      }
    end

    private

    def serialized_offers
      [
        OfferSerializer.new(@variant).serialized_data
      ]
    end
  end
end
