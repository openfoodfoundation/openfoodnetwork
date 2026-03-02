# frozen_string_literal: true

module Reporting
  module Reports
    module BulkCoop
      class CustomerPayments < Base
        def query_result
          table_items.reorder("spree_orders.completed_at").group_by(&:order).values
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

        private

        def customer_payments_total_cost(line_items)
          unique_orders(line_items).map(&:total).compact.sum
        end

        def customer_payments_amount_owed(line_items)
          unique_orders(line_items).map(&:new_outstanding_balance).compact.sum
        end

        def customer_payments_amount_paid(line_items)
          unique_orders(line_items).map(&:payment_total).compact.sum
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
