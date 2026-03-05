# frozen_string_literal: true

module Reporting
  module Reports
    module Payments
      class PaymentTotals < Base
        def columns
          {
            payment_state: proc { |orders| payment_state(orders.first) },
            distributor: proc { |orders| orders.first.distributor.name },
            product_total_price: proc { |orders| orders.map(&:item_total).compact.sum },
            shipping_total_price: proc { |orders| orders.map(&:ship_total).compact.sum },
            total_price: proc { |orders| orders.map(&:total).compact.sum },
            eft_price: proc { |orders| total_by_payment_method(orders, "EFT") },
            paypal_price: proc { |orders| total_by_payment_method(orders, "PayPal") },
            outstanding_balance_price: proc { |orders|
              orders.map(&:outstanding_balance).map(&:amount).compact.sum
            }
          }
        end

        private

        def total_by_payment_method(orders, pay_method)
          orders.map(&:payments).flatten.select { |payment|
            payment.completed? && payment.payment_method&.name.to_s.include?(pay_method)
          }.map(&:amount).compact.sum
        end
      end
    end
  end
end
