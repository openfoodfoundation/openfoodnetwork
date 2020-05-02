# frozen_string_literal: true

# Serializer used to render the products passed
# into JSON-LD format based on DFC ontology
module DfcProvider
  class ProductSerializer
    def initialize(products, base_url)
      @products = products
      @base_url = base_url
    end

    def serialized_json
      {
        "@context" =>
        {
          "DFC" => "http://datafoodconsortium.org/ontologies/DFC_FullModel.owl#",
          "@base" => @base_url
        },
        "@id" => "/enterprise/products",
        "DFC:supplies" => serialized_products
      }.to_json
    end

    private

    def serialized_products
      @products.map do |variant|
        {
          "DFC:description" => variant.name,
          "DFC:quantity" => variant.total_on_hand,
          "@id" => variant.id,
          "DFC:hasUnit" => { "@id" => "/unit/#{variant.unit_description.presence || 'piece'}" }
        }
      end
    end
  end
end
