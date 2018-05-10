module Api
  module Admin
    # Used by admin subscription form
    # Searches for a ship and bill addresses for the customer
    # where they are not already explicitly set
    class SubscriptionCustomerSerializer < CustomerSerializer
      def bill_address
        finder.bill_address
      end

      def ship_address
        finder.ship_address
      end

      def finder
        @finder ||= OpenFoodNetwork::AddressFinder.new(object, object.email)
      end
    end
  end
end
