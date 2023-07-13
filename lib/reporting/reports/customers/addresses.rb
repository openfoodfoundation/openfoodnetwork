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
          end.values.map(&:first)
        end

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

        def skip_duplicate_rows?
          true
        end
      end
    end
  end
end
