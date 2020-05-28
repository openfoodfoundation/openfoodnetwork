require 'open_food_network/reports/bulk_coop_report'

module OpenFoodNetwork::Reports
  class BulkCoopAllocationReport < BulkCoopReport
    def header
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
            proc { |_lis| I18n.t('admin.reports.total') },
            proc { |lis| product_name(lis) },
            proc { |lis| group_buy_unit_size_f(lis) },
            proc { |_lis| "" },
            proc { |_lis| "" },
            proc { |_lis| "" },
            proc { |_lis| "" },
            proc { |lis| total_amount(lis) },
            proc { |lis| total_available(lis) },
            proc { |lis| remainder(lis) },
            proc { |lis| max_quantity_excess(lis) }
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
        proc { |lis| lis.first.order.bill_address.firstname + " " + lis.first.order.bill_address.lastname },
        proc { |lis| lis.first.product.name },
        proc { |lis| lis.first.product.group_buy_unit_size || 0.0 },
        proc { |lis| lis.first.full_name },
        proc { |lis| OpenFoodNetwork::OptionValueNamer.new(lis.first).value },
        proc { |lis| OpenFoodNetwork::OptionValueNamer.new(lis.first).unit },
        proc { |lis| lis.first.weight_from_unit_value || 0 },
        proc { |lis| total_amount(lis) },
        proc { |_lis| "" },
        proc { |_lis| "" },
        proc { |_lis| "" }
      ]
    end
  end
end
