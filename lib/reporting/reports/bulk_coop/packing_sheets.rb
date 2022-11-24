# frozen_string_literal: true

module Reporting
  module Reports
    module BulkCoop
      class PackingSheets < Base
        def query_result
          table_items.group_by do |item|
            [item.order.customer, item.variant]
          end.values
        end

        def columns
          {
            customer: :order_billing_address_name,
            product: :product_name,
            variant: :full_name,
            sum_total: :total_quantity
          }
        end

        private

        def total_quantity(line_items)
          line_items.sum(&:quantity)
        end
      end
    end
  end
end
