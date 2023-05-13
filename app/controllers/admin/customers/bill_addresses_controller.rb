# frozen_string_literal: true

module Admin
  module Customers
    class BillAddressesController < Admin::ResourceController
      include CablecarResponses
      include CustomerAddressModal
      helper_method :address_type

      private

      def address_type
        :bill_address
      end
    end
  end
end
