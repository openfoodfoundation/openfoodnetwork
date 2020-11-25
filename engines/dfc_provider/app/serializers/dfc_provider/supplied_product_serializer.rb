# frozen_string_literal: true

# Serializer used to render a DFC SuppliedProduct from an OFN Variant
# into JSON-LD format based on DFC ontology
module DfcProvider
  class SuppliedProductSerializer < BaseSerializer
    attribute :id, key: '@id'
    attribute :type, key: '@type'
    attribute :unit, key: 'dfc:hasUnit'
    attribute :quantity, key: 'dfc:quantity'
    attribute :description, key: 'dfc:description'
    attribute :total_theoritical_stock, key: 'dfc:totalTheoriticalStock'
    attribute :brand, key: 'dfc:brand'
    attribute :claim, key: 'dfc:claim'
    attribute :image, key: 'dfc:image'
    attribute :life_time, key: 'lifeTime'
    has_many :physical_characteristics, key: 'dfc:physicalCharacterisctics'

    def id
      dfc_provider_routes.api_dfc_provider_enterprise_supplied_product_url(
        enterprise_id: object.product.supplier_id,
        id: object.id,
        host: host
      )
    end

    def type
      'dfc:SuppliedProduct'
    end

    def unit
      {
        '@id' => "/unit/#{unit_name}",
        'rdfs:label' => unit_name
      }
    end

    def quantity
      object.on_hand
    end

    def description
      object.name
    end

    def total_theoritical_stock; end

    def brand; end

    def claim; end

    def image
      object.images.first.try(:attachment, :url)
    end

    def life_time; end

    def physical_characteristics
      []
    end

    private

    def unit_name
      object.unit_description.presence || 'piece'
    end
  end
end
