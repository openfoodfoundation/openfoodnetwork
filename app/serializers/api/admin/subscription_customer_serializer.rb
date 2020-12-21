# frozen_string_literal: true

module Api
  module Admin
    # Used by admin subscription form
    # Searches for a ship and bill addresses for the customer
    # where they are not already explicitly set
    class SubscriptionCustomerSerializer < CustomerSerializer
      delegate :bill_address, to: :finder
      delegate :ship_address, to: :finder

      def finder
        @finder ||= OpenFoodNetwork::AddressFinder.new(object, object.email)
      end
    end
  end
end
