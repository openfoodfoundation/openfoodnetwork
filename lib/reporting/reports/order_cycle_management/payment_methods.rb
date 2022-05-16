# frozen_string_literal: true

module Reporting
  module Reports
    module OrderCycleManagement
      class PaymentMethods < Base
        # rubocop:disable Metrics/AbcSize
        # rubocop:disable Metrics/CyclomaticComplexity
        def columns
          {
            first_name: proc { |order| order.billing_address&.firstname },
            last_name: proc { |order| order.billing_address&.lastname },
            hub: proc { |order| order.distributor&.name },
            customer_code: proc { |order| customer_code(order.email) },
            email: proc { |order| order.email },
            phone: proc { |order| order.billing_address&.phone },
            shipping_method: proc { |order| order.shipping_method&.name },
            payment_method: proc { |order| order.payments.last&.payment_method&.name },
            amount: proc { |order| order.total },
            balance: proc { |order| order.balance_value },
          }
        end
        # rubocop:enable Metrics/AbcSize
        # rubocop:enable Metrics/CyclomaticComplexity
      end
    end
  end
end
