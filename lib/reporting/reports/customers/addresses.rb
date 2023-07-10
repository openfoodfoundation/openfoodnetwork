# frozen_string_literal: true

module Reporting
  module Reports
    module Customers
      class Addresses < Base
        def query_result
          super.group_by do |order|
            {
              first_name: order.billing_address.firstname,
              last_name: order.billing_address.lastname,
              billing_address: order.billing_address.address_and_city,
              email: order.email,
              phone: order.billing_address.phone,
              hub_id: order.distributor_id,
              shipping_method_id: order.shipping_method&.id,
            }
          end.values
        end

        def columns
          {
            first_name: proc { |orders| orders.first.billing_address.firstname },
            last_name: proc { |orders| orders.first.billing_address.lastname },
            billing_address: proc { |orders| orders.first.billing_address.address_and_city },
            email: proc { |orders| orders.first.email },
            phone: proc { |orders| orders.first.billing_address.phone },
            hub: proc { |orders| orders.first.distributor&.name },
            hub_address: proc { |orders| orders.first.distributor&.address&.address_and_city },
            shipping_method: proc { |orders| orders.first.shipping_method&.name },
          }
        end

        def skip_duplicate_rows?
          true
        end
      end
    end
  end
end
