# frozen_string_literal: true

module Reporting
  module Reports
    module BulkCoop
      class CustomerPayments < Base
        def query_result
          table_items.group_by(&:order).values
        end

        def columns
          {
            customer: :order_billing_address_name,
            date_of_order: :order_completed_at,
            total_cost: :customer_payments_total_cost,
            amount_owing: :customer_payments_amount_owed,
            amount_paid: :customer_payments_amount_paid
          }
        end

        def rules
          [
            {
              group_by: :customer,
              header: true,
              summary_row: proc do |_key, _items, rows|
                {
                  total_cost: rows.sum(&:total_cost),
                  amount_owing: rows.sum(&:amount_owing),
                  amount_paid: rows.sum(&:amount_paid),
                }
              end
            }
          ]
        end

        private

        def customer_payments_total_cost(line_items)
          unique_orders(line_items).sum(&:total)
        end

        def customer_payments_amount_owed(line_items)
          unique_orders(line_items).sum(&:new_outstanding_balance)
        end

        def customer_payments_amount_paid(line_items)
          unique_orders(line_items).sum(&:payment_total)
        end

        def unique_orders(line_items)
          line_items.map(&:order).uniq
        end

        def order_completed_at(line_items)
          line_items.first.order.completed_at
        end
      end
    end
  end
end
