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

        # rubocop:disable Metrics/AbcSize
        # rubocop:disable Metrics/CyclomaticComplexity
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
            total_orders: proc { |orders| orders.count },
            total_incl_tax: proc { |orders| orders.sum(&:total) },
            last_completed_order_date: proc { |orders|
                                         orders.max_by(&:completed_at)&.completed_at&.to_date
                                       },
          }
        end
        # rubocop:enable Metrics/AbcSize
        # rubocop:enable Metrics/CyclomaticComplexity

        def skip_duplicate_rows?
          true
        end
      end
    end
  end
end
