# frozen_string_literal: true

module Reporting
  module Reports
    module BulkCoop
      class BulkCoopAllocationReport
        def table_headers
          [
            I18n.t(:report_header_customer),
            I18n.t(:report_header_product),
            I18n.t(:report_header_bulk_unit_size),
            I18n.t(:report_header_variant),
            I18n.t(:report_header_variant_value),
            I18n.t(:report_header_variant_unit),
            I18n.t(:report_header_weight),
            I18n.t(:report_header_sum_total),
            I18n.t(:report_header_total_available),
            I18n.t(:report_header_unallocated),
            I18n.t(:report_header_max_quantity_excess),
          ]
        end

        def rules
          [
            {
              group_by: proc { |line_item| line_item.product },
              sort_by: proc { |product| product.name },
              summary_columns: [
                :total_label,
                :variant_product_name,
                :variant_product_group_buy_unit_size_f,
                :empty_cell,
                :empty_cell,
                :empty_cell,
                :empty_cell,
                :total_amount,
                :total_available,
                :remainder,
                :max_quantity_excess
              ]
            },
            {
              group_by: proc { |line_item| line_item.order },
              sort_by: proc { |order| order.to_s }
            }
          ]
        end

        def columns
          [
            :order_billing_address_name,
            :product_name,
            :product_group_buy_unit_size,
            :full_name,
            :option_value_value,
            :option_value_unit,
            :weight_from_unit_value,
            :total_amount,
            :empty_cell,
            :empty_cell,
            :empty_cell
          ]
        end
      end
    end
  end
end
