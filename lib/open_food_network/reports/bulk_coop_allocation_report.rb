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

    organise do
      group { |li| li.product }
      sort(&:name)

      summary_row do
        column { |lis| I18n.t('admin.reports.total') }
        column { |lis| product_name(lis) }
        column { |lis| group_buy_unit_size_f(lis) }
        column { |lis| "" }
        column { |lis| "" }
        column { |lis| "" }
        column { |lis| "" }
        column { |lis| total_amount(lis) }
        column { |lis| total_available(lis) }
        column { |lis| remainder(lis) }
        column { |lis| max_quantity_excess(lis) }
      end

      organise do
        group { |li| li.full_name }
        sort { |full_name| full_name }

        organise do
          group { |li| li.order }
          sort { |order| order.to_s }
        end
      end
    end

    columns do
      column { |lis| lis.first.order.bill_address.firstname + " " + lis.first.order.bill_address.lastname }
      column { |lis| lis.first.product.name }
      column { |lis| lis.first.product.group_buy_unit_size || 0.0 }
      column { |lis| lis.first.full_name }
      column { |lis| OpenFoodNetwork::OptionValueNamer.new(lis.first).value }
      column { |lis| OpenFoodNetwork::OptionValueNamer.new(lis.first).unit }
      column { |lis| lis.first.weight_from_unit_value || 0 }
      column { |lis| total_amount(lis) }
      column { |lis| "" }
      column { |lis| "" }
      column { |lis| "" }
    end
  end
end
