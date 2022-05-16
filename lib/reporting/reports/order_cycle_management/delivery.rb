# frozen_string_literal: true

module Reporting
  module Reports
    module OrderCycleManagement
      class Delivery < Base
        # rubocop:disable Metrics/AbcSize
        def columns
          {
            first_name: proc { |order| order.shipping_address.firstname },
            last_name: proc { |order| order.shipping_address.lastname },
            hub: proc { |order| order.distributor&.name },
            customer_code: proc { |order| customer_code(order.email) },
            delivery_address: proc { |order| order.shipping_address.address_and_city },
            delivery_postcode: proc { |order| order.shipping_address.zipcode },
            phone: proc { |order| order.shipping_address.phone },
            shipping_method: proc { |order| order.shipping_method&.name },
            payment_method: proc { |order| order.payments.first&.payment_method&.name },
            amount: proc { |order| order.total },
            balance: proc { |order| order.balance_value },
            temp_controlled_items: proc { |order| has_temperature_controlled_items?(order) },
            special_instructions: proc { |order| order.special_instructions },
          }
        end
        # rubocop:enable Metrics/AbcSize

        def has_temperature_controlled_items?(order)
          order.line_items.any? { |line_item|
            line_item.product.shipping_category&.temperature_controlled
          }
        end
      end
    end
  end
end
