# frozen_string_literal: true

module Reporting
  module Reports
    module Payments
      class PaymentTotals < Base
        def columns
          {
            payment_state: proc { |orders| payment_state(orders.first) },
            distributor: proc { |orders| orders.first.distributor.name },
            product_total_price: proc { |orders| orders.map(&:item_total).sum(&:to_f) },
            shipping_total_price: proc { |orders| orders.map(&:ship_total).sum(&:to_f) },
            total_price: proc { |orders| orders.map(&:total).sum(&:to_f) },
            eft_price: proc { |orders| total_by_payment_method(orders, "EFT") },
            paypal_price: proc { |orders| total_by_payment_method(orders, "PayPal") },
            outstanding_balance_price: proc { |orders|
              orders.map(&:outstanding_balance).sum(&:to_f)
            }
          }
        end

        private

        def total_by_payment_method(orders, pay_method)
          orders.map(&:payments).flatten.select { |payment|
            payment.completed? && payment.payment_method&.name.to_s.include?(pay_method)
          }.map(&:amount).sum(&:to_f)
        end
      end
    end
  end
end
