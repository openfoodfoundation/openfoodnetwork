# frozen_string_literal: true

module Reporting
  module Reports
    module BulkCoop
      class SupplierReport < Base
        def query_result
          table_items.group_by(&:variant).values
        end

        def columns
          {
            producer: :variant_product_producer_name,
            producer_id: :variant_product_producer_id,
            product: :variant_product_name,
            bulk_unit_size: :variant_product_group_buy_unit_size_f,
            variant: :full_name,
            variant_value: :option_value_value,
            variant_unit: :option_value_unit,
            weight: :weight_from_unit_value,
            sum_total: :total_amount,
            units_required: :empty_cell,
            unallocated: :empty_cell,
            max_quantity_excess: :empty_cell
          }
        end

        def rules
          [
            {
              group_by: :supplier,
              header: true,
              summary_row: proc do |_key, items, rows|
                line_items = items.flatten
                {
                  sum_total: rows.sum(&:sum_total),
                  units_required: units_required(line_items),
                  unallocated: remainder(line_items),
                  max_quantity_excess: max_quantity_excess(line_items)
                }
              end
            }
          ]
        end

        def default_params
          {
            fields_to_hide: [:producer_id, :variant_value, :variant_unit]
          }
        end

        private

        def variant_product_producer_name(line_items)
          line_items.first.variant.product.supplier.name
        end

        def variant_product_producer_id(line_items)
          line_items.first.variant.product.supplier.id
        end
      end
    end
  end
end
