require 'open_food_network/reports/bulk_coop_report'

module OpenFoodNetwork::Reports
  class BulkCoopSupplierReport < BulkCoopReport
    header "Supplier", "Product", "Bulk Unit Size", "Variant", "Variant value", "Variant unit", "Weight", "Sum Total", "Units Required", "Unallocated", "Max quantity excess"

    organise do
      group { |li| li.product.supplier }
      sort &:name

      organise do
        group { |li| li.product }
        sort &:name

        summary_row do
          column { |lis| supplier_name(lis) }
          column { |lis| product_name(lis) }
          column { |lis| group_buy_unit_size_f(lis) }
          column { |lis| "" }
          column { |lis| "" }
          column { |lis| "" }
          column { |lis| "" }
          column { |lis| total_amount(lis) }
          column { |lis| units_required(lis) }
          column { |lis| remainder(lis) }
          column { |lis| max_quantity_excess(lis) }
        end

        organise do
          group { |li| li.full_name }
          sort { |full_name| full_name }
        end
      end
    end

    columns do
      column { |lis| supplier_name(lis) }
      column { |lis| product_name(lis) }
      column { |lis| group_buy_unit_size_f(lis) }
      column { |lis| lis.first.full_name }
      column { |lis| OpenFoodNetwork::OptionValueNamer.new(lis.first).value }
      column { |lis| OpenFoodNetwork::OptionValueNamer.new(lis.first).unit }
      column { |lis| lis.first.weight_from_unit_value || 0 }
      column { |lis| total_amount(lis) }
      column { |lis| '' }
      column { |lis| '' }
      column { |lis| '' }
    end
  end
end
