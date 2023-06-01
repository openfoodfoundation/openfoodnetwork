# frozen_string_literal: true

module Reporting
  module Reports
    module OrdersAndFulfillment
      class OrderCycleSupplierTotalsByDistributor < Base
        def columns
          {
            producer: supplier_name,
            product: product_name,
            variant: variant_name,
            hub: hub_name,
            quantity: proc { |line_items| line_items.to_a.sum(&:quantity) },
            curr_cost_per_unit: proc { |line_items| line_items.first.price },
            total_cost: proc { |line_items| line_items.sum(&:amount) },
            shipping_method: proc { |line_items| line_items.first.order.shipping_method&.name }
          }
        end

        def rules
          [
            {
              group_by: :producer,
              header: true,
            },
            {
              group_by: proc { |line_items, _row| line_items.first.variant },
              sort_by: proc { |variant| variant.product.name }
            },
            {
              group_by: :hub,
              summary_row: proc do |_key, _items, rows|
                {
                  quantity: rows.sum(&:quantity),
                  total_cost: rows.sum(&:total_cost)
                }
              end,
            }
          ]
        end

        def line_item_includes
          [{ order: :distributor,
             variant: { product: :supplier } }]
        end
      end
    end
  end
end
