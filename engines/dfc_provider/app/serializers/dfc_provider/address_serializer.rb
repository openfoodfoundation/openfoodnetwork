# frozen_string_literal: true

# Serializer used to render the DFC Address from an OFN User
# into JSON-LD format based on DFC ontology
module DfcProvider
  class AddressSerializer < ActiveModel::Serializer
    include RouteHelper

    attribute :type, key: '@type'
    attribute :city, key: 'dfc-b:city'
    attribute :country, key: 'dfc-b:country'
    attribute :postcode, key: 'dfc-b:postcode'
    attribute :street, key: 'dfc-b:street'

    def type
      'dfc-b:Address'
    end

    def city; end

    def country; end

    def postcode; end

    def street; end
  end
end
