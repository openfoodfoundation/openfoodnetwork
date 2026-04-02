# frozen_string_literal: true

module Reporting
  module Reports
    module Payments
      class ItemisedPaymentTotals < Base
        def columns
          {
            payment_state: proc { |orders| payment_state(orders.first) },
            distributor: proc { |orders| orders.first.distributor.name },
            product_total_price: proc { |orders| orders.map(&:item_total).compact.sum },
            shipping_total_price: proc { |orders| orders.map(&:ship_total).compact.sum },
            outstanding_balance_price: proc do |orders|
              orders.map(&:outstanding_balance).map(&:amount).compact.sum
            end,
            total_price: proc { |orders| orders.map(&:total).compact.sum }
          }
        end
      end
    end
  end
end
