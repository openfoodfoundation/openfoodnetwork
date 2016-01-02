require 'open_food_network/reports/bulk_coop_report'

module OpenFoodNetwork::Reports
  class BulkCoopAllocationReport < BulkCoopReport
    header 'Customer', 'Product', 'Bulk Unit Size', 'Variant', 'Variant value', 'Variant unit', 'Weight', 'Sum Total', 'Total Available', 'Unallocated', 'Max quantity excess'

    organise do
      group(&:product)
      sort &:name

      summary_row do
        column { |_lis| 'TOTAL' }
        column { |lis| product_name(lis) }
        column { |lis| group_buy_unit_size_f(lis) }
        column { |_lis| '' }
        column { |_lis| '' }
        column { |_lis| '' }
        column { |_lis| '' }
        column { |lis| total_amount(lis) }
        column { |lis| total_available(lis) }
        column { |lis| remainder(lis) }
        column { |lis| max_quantity_excess(lis) }
      end

      organise do
        group(&:full_name)
        sort { |full_name| full_name }

        organise do
          group(&:order)
          sort(&:to_s)
        end
      end
    end

    columns do
      column { |lis| lis.first.order.bill_address.firstname + ' ' + lis.first.order.bill_address.lastname }
      column { |lis| lis.first.product.name }
      column { |lis| lis.first.product.group_buy_unit_size || 0.0 }
      column { |lis| lis.first.full_name }
      column { |lis| OpenFoodNetwork::OptionValueNamer.new(lis.first).value }
      column { |lis| OpenFoodNetwork::OptionValueNamer.new(lis.first).unit }
      column { |lis| lis.first.weight_from_unit_value || 0 }
      column { |lis| total_amount(lis) }
      column { |_lis| '' }
      column { |_lis| '' }
      column { |_lis| '' }
    end
  end
end
