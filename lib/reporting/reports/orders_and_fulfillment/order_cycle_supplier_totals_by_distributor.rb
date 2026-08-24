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
            quantity: proc { |line_items| line_items.to_a.map(&:quantity).sum(&:to_i) },
            curr_cost_per_unit: proc { |line_items| line_items.first.price },
            total_cost: proc { |line_items| line_items.map(&:amount).compact.sum },
            shipping_method: proc { |line_items| line_items.first.order.shipping_method&.name }
          }
        end

        def query_result
          report_line_items.list(line_item_includes).group_by { |li|
            [
              li.variant_id,
              li.price,
              li.order.distributor_id,
              li.order.shipping_method&.id
            ]
          }.values
        end

        def rules
          [
            {
              group_by: :producer,
              header: true,
            },
            {
              group_by: proc { |line_items, _row| line_items.first.variant },
              sort_by: proc { |variant| variant.line_items.first.full_product_name }
            },
            {
              group_by: :hub,
              summary_row: proc do |_key, _items, rows|
                {
                  quantity: rows.map(&:quantity).sum(&:to_i),
                  total_cost: rows.map(&:total_cost).compact.sum
                }
              end,
            }
          ]
        end

        def line_item_includes
          [{ order: [
               :distributor,
               { shipments: { shipping_rates: :shipping_method } }
             ],
             variant: [:product, :enterprise] }]
        end
      end
    end
  end
end
