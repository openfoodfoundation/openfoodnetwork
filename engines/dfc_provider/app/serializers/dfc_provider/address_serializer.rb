# frozen_string_literal: true

# Serializer used to render the DFC Address from an OFN User
# into JSON-LD format based on DFC ontology
module DfcProvider
  class AddressSerializer < BaseSerializer
    attribute :type, key: '@type'
    attribute :city, key: 'dfc:city'
    attribute :country, key: 'dfc:country'
    attribute :postcode, key: 'dfc:postcode'
    attribute :street, key: 'dfc:street'

    def type
      'dfc:Address'
    end

    def city; end

    def country; end

    def postcode; end

    def street; end
  end
end
