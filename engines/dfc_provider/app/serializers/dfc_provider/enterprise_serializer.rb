# frozen_string_literal: true

# Serializer used to render a DFC Enterprise from an OFN Enterprise
# into JSON-LD format based on DFC ontology
module DfcProvider
  class EnterpriseSerializer < ActiveModel::Serializer
    attribute :id, key: '@id'
    attribute :type, key: '@type'
    attribute :vat_number, key: 'dfc:VATnumber'
    has_many :defines, key: 'dfc:defines'
    has_many :supplies,
             key: 'dfc:supplies',
             serializer: DfcProvider::SuppliedProductSerializer
    has_many :manages,
             key: 'dfc:manages',
             serializer: DfcProvider::CatalogItemSerializer

    def id
      "/entreprises/#{object.id}"
    end

    def type
      'dfc:Entreprise'
    end

    def vat_number; end

    def defines
      []
    end

    def supplies
      products
    end

    def manages
      products.map(&:variants).flatten
    end

    private

    def products
      @products ||=
        object.
          supplied_products.
          includes(variants: :product)
    end
  end
end
