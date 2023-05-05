# frozen_string_literal: true

module Reporting
  module Reports
    module OrdersAndFulfillment
      class OrderCycleDistributorTotalsBySupplier < Base
        def columns
          {
            hub: hub_name,
            producer: supplier_name,
            product: product_name,
            variant: variant_name,
            quantity: proc { |line_items| line_items.to_a.sum(&:quantity) },
            curr_cost_per_unit: proc { |line_items| line_items.first.price },
            total_cost: proc { |line_items| line_items.sum(&:amount) },
            total_shipping_cost: proc { |_line_items| "" },
            shipping_method: proc { |line_items| line_items.first.order.shipping_method&.name }
          }
        end

        def rules
          [
            {
              group_by: :hub,
              header: proc { |key, _items, _rows| "#{I18n.t(:report_header_hub)} #{key}" },
              summary_row: proc do |_key, line_items, rows|
                {
                  total_cost: rows.sum(&:total_cost),
                  total_shipping_cost: line_items.map(&:first).map(&:order).uniq.sum(&:ship_total)
                }
              end
            }
          ]
        end

        def line_item_includes
          [{
            order: [
              :distributor,
              :adjustments,
              { shipments: { shipping_rates: :shipping_method } }
            ],
            variant: { product: :supplier }
          }]
        end
      end
    end
  end
end
