# frozen_string_literal: true

# Serializer used to render the products passed
# into JSON-LD format based on DFC ontology
module DfcProvider
  class ProductSerializer
    def initialize(products, base_url)
      @products = products
      @base_url = base_url
    end

    def serialized_data
      {
        "@context" =>
        {
          "dfc" => "http://datafoodconsortium.org/ontologies/DFC_FullModel.owl#",
          "@base" => @base_url
        },
        "@id" => "/enterprise/default/products",
        "@id" => "/personId",
        "@type"=> "dfc:Person",
        "dfc:familyName" => "Doe",
        "dfc:firtsName" => "Jhon",
        "dfc:hasAdress" => {
          "@type" => "dfc:Address",
          "dfc:city" =>"",
          "dfc:country" =>"",
          "dfc:postcode" => "",
          "dfc:street" => ""
        },
        "dfc:affiliates" => [
          {
            "@id" => "/entrepriseId",
            "@type" => "dfc:Entreprise",
            "dfc:VATnumber" => "",
            "dfc:defines" => [],
            "dfc:supplies" => supplied_products,
            "dfc:manages" => managed_products
          }
        ]
      }
    end

    private

    def supplied_products
      @products.map do |product|
        variant = product.variants.first
        {
          "@id" => "/products/#{product.id}",
          "dfc:hasUnit":{
            "@id" => "/unit/#{variant.unit_description.presence || 'piece'}",
            "rdfs:label" => "#{variant.unit_description.presence || 'piece'}"
          },
          "dfc:quantity" => "99.99",
          "dfc:description" => product.name,
          "dfc:totalTheoriticalStock" => nil,
          "dfc:brand" => '',
          "dfc:claim" => '',
          "dfc:image" => product.images.first.try(:attahcement, :url),
          "lifeTime" => "supply lifeTime",
          "dfc:physicalCharacterisctics" => "supply physical characterisctics",
          "dfc:quantity" => "supply quantity"
        }
      end
    end

    def managed_products
      @products.map do |product|
        product.variants.map do |variant|
          {
            "@id" => "/catalogItemId1",
            "@type" => "dfc:CatalogItem",
            "dfc:references" => {
              "@type" => "@id",
              "@id" => "/suppliedProduct/item3"
            },
            "dfc:sku" => product.sku,
            "dfc:stockLimitation" => nil,
            "dfc:offeredThrough" => [
              {
                "@id" => "offerId1",
                "@type" => "dfc:Offer",
                "dfc:offeresTo" => {
                  "@type" => "@id",
                  "@id" => "/customerCategoryId1"
                },
                "dfc:price" => variant.price,
                "dfc:stockLimitation" => 0,
              }
            ]
          }
        end
      end.flatten
    end
  end
end
