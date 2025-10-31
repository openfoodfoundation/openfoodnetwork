# frozen_string_literal: true

module Reporting
  module Reports
    module Payments
      class ItemisedPaymentTotals < Base
        def columns
          {
            payment_state: proc { |orders| payment_state(orders.first) },
            distributor: proc { |orders| orders.first.distributor.name },
            product_total_price: proc { |orders| orders.map(&:item_total).sum(&:to_f) },
            shipping_total_price: proc { |orders| orders.map(&:ship_total).sum(&:to_f) },
            outstanding_balance_price: proc do |orders|
              orders.map(&:outstanding_balance).sum(&:to_f)
            end,
            total_price: proc { |orders| orders.map(&:total).sum(&:to_f) }
          }
        end
      end
    end
  end
end
