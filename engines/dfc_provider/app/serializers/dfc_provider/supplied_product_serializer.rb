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
          "@id" => "/unit/#{@product.unit_description.presence || 'piece'}",
          "rdfs:label" => "#{@product.unit_description.presence || 'piece'}"
        },
        "dfc:quantity" => @product.total_on_hand,
        "dfc:description" => @product.name,
        "dfc:totalTheoriticalStock" => nil,
        "dfc:brand" => nil,
        "dfc:claim" => nil,
        "dfc:image" => @product.images.first.try(:attachment, :url),
        "lifeTime" => nil,
        "dfc:physicalCharacterisctics" => nil
      }
    end
  end
end
