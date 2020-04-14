module DfcProvider
  class ProductSerializer
    def initialize(enterprise, products, base_url)
      @enterprise = enterprise
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
         "@id" => "/enterprises/#{@enterprise.id}/products",
         "DFC:supplies" => @products.map do |variant|
            {
              "DFC:description" => variant.name,
              "DFC:quantity" => variant.total_on_hand,
              "@id" => variant.id,
              "DFC:hasUnit" => {"@id" => "/unit/#{variant.unit_description.presence || 'piece' }"}
            }
          end
        }.to_json
    end
  end
end
