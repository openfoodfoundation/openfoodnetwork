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
            quantity: proc { |line_items| line_items.sum(&:quantity) },
            total_units: proc { |line_items| total_units(line_items) },
            curr_cost_per_unit: proc { |line_items| line_items.first.price },
            total_cost: proc { |line_items| line_items.sum(&:amount) },
            sku: variant_sku,
            producer_charges_sales_tax?: supplier_charges_sales_tax?,
            product_tax_category: product_tax_category
          }
        end

        def rules
          [
            {
              group_by: :producer,
              header: true,
              summary_row: proc do |_key, _items, rows|
                total_units = rows.map(&:total_units)
                summary_total_units = if total_units.all?(&:present?)
                                        rows.sum(&:total_units)
                                      else
                                        " "
                                      end
                {
                  quantity: rows.sum(&:quantity),
                  total_units: summary_total_units,
                  total_cost: rows.sum(&:total_cost)
                }
              end
            }
          ]
        end

        def line_item_includes
          [{ variant: { product: :supplier } }]
        end

        def query_result
          report_line_items.list(line_item_includes).group_by { |e|
            [e.variant_id, e.price]
          }.values
        end

        def default_params
          super.merge({ fields_to_hide: [
                        :sku,
                        :producer_charges_sales_tax?,
                        :product_tax_category
                      ] })
        end
      end
    end
  end
end
