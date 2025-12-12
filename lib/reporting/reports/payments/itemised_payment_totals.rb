# frozen_string_literal: true

module Reporting
  module Reports
    module Payments
      class ItemisedPaymentTotals < Base
        def columns
          {
            payment_state: proc { |orders| payment_state(orders.first) },
            distributor: proc { |orders| orders.first.distributor.name },
            product_total_price: proc { |orders| prices_sum(orders.map(&:item_total)) },
            shipping_total_price: proc { |orders| prices_sum(orders.map(&:ship_total)) },
            outstanding_balance_price: proc do |orders|
              prices_sum(orders.map(&:outstanding_balance))
            end,
            total_price: proc { |orders| prices_sum(orders.map(&:total)) }
          }
        end
      end
    end
  end
end
