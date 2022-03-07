# frozen_string_literal: true

module Api
  module V1
    class AddressSerializer < BaseSerializer
      attributes :phone, :latitude, :longitude

      attribute :first_name, &:firstname
      attribute :last_name, &:lastname
      attribute :street_address_1, &:address1
      attribute :street_address_2, &:address2
      attribute :postal_code, &:zipcode
      attribute :locality, &:city
      attribute :region, &:state_name
      attribute :country, ->(object, _) { object.country.name }
    end
  end
end
