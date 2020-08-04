# frozen_string_literal: true

# Serializer used to render a DFC SuppliedProduct from an OFN Product
# into JSON-LD format based on DFC ontology
module DfcProvider
  class SuppliedProductSerializer
    def initialize(product)
      @product = product
    end

    def serialized_data
      {
        "@id" => "/products/#{@product.id}",
        "dfc:hasUnit" => {
          "@id" => "/unit/#{unit_name}",
          "rdfs:label" => unit_name
        },
        "dfc:quantity" => @product.on_hand,
        "dfc:description" => @product.name,
        "dfc:totalTheoriticalStock" => nil,
        "dfc:brand" => nil,
        "dfc:claim" => nil,
        "dfc:image" => @product.images.first.try(:attachment, :url),
        "lifeTime" => nil,
        "dfc:physicalCharacterisctics" => nil
      }
    end

    private

    def unit_name
      @product.unit_description.presence || 'piece'
    end
  end
end
