# frozen_string_literal: true

module Reporting
  module Reports
    module Customers
      class Addresses < Base
        def columns
          {
            first_name: proc { |order| order.billing_address.firstname },
            last_name: proc { |order| order.billing_address.lastname },
            billing_address: proc { |order| address_from(order.billing_address) },
            email: proc { |order| order.email },
            phone: proc { |order| order.billing_address.phone },
            hub: proc { |order| order.distributor&.name },
            hub_address: proc { |order| address_from(order.distributor&.address) },
            shipping_method: proc { |order| order.shipping_method&.name },
          }
        end

        private

        def address_from(address)
          [address&.address1, address&.address2, address&.city].join(" ")
        end
      end
    end
  end
end
