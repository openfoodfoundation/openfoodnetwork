# frozen_string_literal: true

module Reporting
  module Reports
    module Payments
      class PaymentsByPaymentType < Base
        def query_result
          payments = search.result.includes(payments: :payment_method).map do |order|
            order.payments.select(&:completed?)
          end.flatten
          payments.group_by { |payment|
            [payment.order.payment_state, payment.order.distributor, payment.payment_method]
          }.values
        end

        def columns
          {
            payment_state: proc { |payments| payment_state(payments.first.order) },
            distributor: proc { |payments| payments.first.order.distributor.name },
            payment_type: proc { |payments| payments.first.payment_method&.name },
            total_price: proc { |payments| payments.sum(&:amount) }
          }
        end
      end
    end
  end
end
