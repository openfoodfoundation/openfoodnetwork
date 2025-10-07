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
            quantity: proc { |line_items| line_items.map(&:quantity).sum(&:to_i) },
            total_units: proc { |line_items| total_units(line_items) },
            curr_cost_per_unit: proc { |line_items| line_items.first.price },
            total_cost: proc { |line_items| line_items.map(&:amount).sum(&:to_f) },
            sku: variant_sku,
            producer_charges_sales_tax?: supplier_charges_sales_tax?,
            product_tax_category:
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
                                        rows.map(&:total_units).sum(&:to_f)
                                      else
                                        " "
                                      end
                {
                  quantity: rows.map(&:quantity).sum(&:to_i),
                  total_units: summary_total_units,
                  total_cost: rows.map(&:total_cost).sum(&:to_f)
                }
              end
            }
          ]
        end

        def line_item_includes
          [{ variant: [:supplier, :product] }]
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
