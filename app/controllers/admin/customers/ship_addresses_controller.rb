# frozen_string_literal: true

module Admin
  module Customers
    class ShipAddressesController < Admin::ResourceController
      include CablecarResponses
      include CustomerAddressModal
      helper_method :address_type

      private

      def address_type
        :ship_address
      end
    end
  end
end
