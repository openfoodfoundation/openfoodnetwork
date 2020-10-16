# frozen_string_literal: true

require 'open_food_network/address_finder'

module Api
  module Admin
    class UserSerializer < ActiveModel::Serializer
      attributes :id, :email, :confirmed

      has_one :ship_address, serializer: Api::AddressSerializer
      has_one :bill_address, serializer: Api::AddressSerializer

      def ship_address
        OpenFoodNetwork::AddressFinder.new(object.email, object).ship_address
      end

      def bill_address
        OpenFoodNetwork::AddressFinder.new(object.email, object).bill_address
      end

      def confirmed
        object.confirmed?
      end
    end
  end
end
