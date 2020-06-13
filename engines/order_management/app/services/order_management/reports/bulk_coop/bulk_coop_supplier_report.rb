# frozen_string_literal: true

module OrderManagement
  module Reports
    module BulkCoop
      class BulkCoopSupplierReport
        def header
          [
            I18n.t(:report_header_supplier),
            I18n.t(:report_header_product),
            I18n.t(:report_header_bulk_unit_size),
            I18n.t(:report_header_variant),
            I18n.t(:report_header_variant_value),
            I18n.t(:report_header_variant_unit),
            I18n.t(:report_header_weight),
            I18n.t(:report_header_sum_total),
            I18n.t(:report_header_units_required),
            I18n.t(:report_header_unallocated),
            I18n.t(:report_header_max_quantity_excess),
          ]
        end

        def rules
          [
            { group_by: proc { |line_item| line_item.product.supplier },
              sort_by: proc { |supplier| supplier.name } },
            { group_by: proc { |line_item| line_item.product },
              sort_by: proc { |product| product.name },
              summary_columns: [
                :variant_product_supplier_name,
                :variant_product_name,
                :variant_product_group_buy_unit_size_f,
                :empty_cell,
                :empty_cell,
                :empty_cell,
                :empty_cell,
                :total_amount,
                :units_required,
                :remainder,
                :max_quantity_excess
              ] },
            { group_by: proc { |line_item| line_item.full_name },
              sort_by: proc { |full_name| full_name } }
          ]
        end

        def columns
          [
            :variant_product_supplier_name,
            :variant_product_name,
            :variant_product_group_buy_unit_size_f,
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
