# frozen_string_literal: true

# Serializer used to render a DFC Enterprise from an OFN Enterprise
# into JSON-LD format based on DFC ontology
module DfcProvider
  class EnterpriseSerializer
    def initialize(enterprise)
      @enterprise = enterprise
    end

    def serialized_data
      {
        "@id" => "/entreprises/#{@enterprise.id}",
        "@type" => "dfc:Entreprise",
        "dfc:VATnumber" => nil,
        "dfc:defines" => [],
        "dfc:supplies" => serialized_supplied_products,
        "dfc:manages" => serialized_catalog_items
      }
    end

    private

    def products
      @products ||= @enterprise.
                    supplied_products.
                    includes(variants: :product)
    end

    def serialized_supplied_products
      products.map do |product|
        SuppliedProductSerializer.new(product).serialized_data
      end
    end

    def serialized_catalog_items
      @products.map do |product|
        product.variants.map do |variant|
          CatalogItemSerializer.new(variant).serialized_data
        end
      end.flatten
    end
  end
end
