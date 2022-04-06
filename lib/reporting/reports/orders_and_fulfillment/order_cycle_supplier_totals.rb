# frozen_string_literal: true

module Reporting
  module Reports
    module OrdersAndFulfillment
      class OrderCycleSupplierTotals < Base
        def columns
          {
            producer: supplier_name,
            product: product_name,
            variant: variant_name,
            curr_cost_per_unit: proc { |line_items| line_items.first.price },
            quantity: proc { |line_items| line_items.sum(&:quantity) },
            total_units: proc { |line_items| total_units(line_items) },
            total_cost: proc { |line_items| line_items.sum(&:amount) },
          }
        end

        def rules
          [
            {
              group_by: :producer,
              header: true,
              summary_row: proc do |_key, _items, rows|
                {
                  quantity: rows.sum(&:quantity),
                  total_units: rows.sum(&:total_units),
                  total_cost: rows.sum(&:total_cost)
                }
              end
            }
          ]
        end

        def line_item_includes
          [{ variant: [{ option_values: :option_type }, { product: :supplier }] }]
        end
      end
    end
  end
end
