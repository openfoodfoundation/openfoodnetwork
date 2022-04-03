# frozen_string_literal: true

module Reporting
  module Reports
    module Customers
      class Addresses < Base
        def columns
          {
            first_name: proc { |order| order.billing_address.firstname },
            last_name: proc { |order| order.billing_address.lastname },
            billing_address: proc { |order| order.billing_address.address_and_city },
            email: proc { |order| order.email },
            phone: proc { |order| order.billing_address.phone },
            hub: proc { |order| order.distributor&.name },
            hub_address: proc { |order| order.distributor&.address&.address_and_city },
            shipping_method: proc { |order| order.shipping_method&.name },
          }
        end
      end
    end
  end
end
