# frozen_string_literal: true

# Serializer used to render a DFC Enterprise from an OFN Enterprise
# into JSON-LD format based on DFC ontology
module DfcProvider
  class EnterpriseSerializer < BaseSerializer
    attribute :id, key: '@id'
    attribute :type, key: '@type'
    attribute :vat_number, key: 'dfc:VATnumber'
    has_many :defines, key: 'dfc:defines'
    has_many :supplies,
             key: 'dfc-b:supplies',
             serializer: DfcProvider::SuppliedProductSerializer
    has_many :manages,
             key: 'dfc-b:manages',
             serializer: DfcProvider::CatalogItemSerializer

    def id
      dfc_provider_routes.enterprise_url(
        id: object.id,
      )
    end

    def type
      'dfc:Entreprise'
    end

    def vat_number; end

    def defines
      []
    end

    def supplies
      DfcProvider::VariantFetcher.new(object).scope
    end

    def manages
      DfcProvider::VariantFetcher.new(object).scope
    end
  end
end
