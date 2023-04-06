# frozen_string_literal: true

module Reporting
  module Reports
    module Payments
      class ItemisedPaymentTotals < Base
        def columns
          {
            payment_state: proc { |orders| payment_state(orders.first) },
            distributor: proc { |orders| orders.first.distributor.name },
            product_total_price: proc { |orders| orders.to_a.sum(&:item_total) },
            shipping_total_price: proc { |orders| orders.sum(&:ship_total) },
            outstanding_balance_price: proc do |orders|
              orders.sum { |order| order.outstanding_balance.to_f }
            end,
            total_price: proc { |orders| orders.map(&:total).sum }
          }
        end
      end
    end
  end
end
