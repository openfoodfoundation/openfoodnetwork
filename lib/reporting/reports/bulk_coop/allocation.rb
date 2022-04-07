# frozen_string_literal: true

module Reporting
  module Reports
    module BulkCoop
      class Allocation < Base
        def query_result
          table_items.group_by(&:order).values
        end

        def columns
          {
            customer: :order_billing_address_name,
            product: :product_name,
            bulk_unit_size: :product_group_buy_unit_size,
            variant: :full_name,
            variant_value: :option_value_value,
            variant_unit: :option_value_unit,
            weight: :weight_from_unit_value,
            sum_total: :total_amount,
            total_available: :empty_cell,
            unallocated: :empty_cell,
            max_quantity_excess: :empty_cell
          }
        end

        def rules
          [
            {
              group_by: :product,
              header: true,
              summary_row: proc do |_key, items, rows|
                line_items = items.flatten
                {
                  sum_total: rows.sum(&:sum_total),
                  total_available: total_available(line_items),
                  unallocated: remainder(line_items),
                  max_quantity_excess: max_quantity_excess(line_items)
                }
              end
            }
          ]
        end
      end
    end
  end
end
