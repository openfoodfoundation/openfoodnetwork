require 'open_food_network/reports/bulk_coop_report'

module OpenFoodNetwork::Reports
  class BulkCoopAllocationReport < BulkCoopReport
    header "Customer", "Product", "Unit Size", "Variant", "Weight", "Sum Total", "Sum Max Total", "Total Allocated", "Remainder"

    organise do
        group { |li| li.variant.product }
        sort &:name

        summary_row do
          column { |lis| "TOTAL" }
          column { |lis| product_name(lis) }
          column { |lis| group_buy_unit_size_f(lis) }
          column { |lis| "" }
          column { |lis| "" }
          column { |lis| total_amount(lis) }
          column { |lis| total_max_quantity_amount(lis) }
          column { |lis| ( (lis.first.variant.product.group_buy_unit_size || 0).zero? ? 0 : ( lis.sum { |li| ( [li.max_quantity || 0, li.quantity || 0].max ) * (li.variant.weight || 0) } / lis.first.variant.product.group_buy_unit_size ) ).floor * (lis.first.variant.product.group_buy_unit_size || 0) }
          column { |lis| lis.sum { |li| ( [li.max_quantity || 0, li.quantity || 0].max ) * (li.variant.weight || 0) } - ( ( (lis.first.variant.product.group_buy_unit_size || 0).zero? ? 0 : ( lis.sum { |li| ( [li.max_quantity || 0, li.quantity || 0].max ) * (li.variant.weight || 0) } / lis.first.variant.product.group_buy_unit_size ) ).floor * (lis.first.variant.product.group_buy_unit_size || 0) ) }
        end

        organise do
          group { |li| li.variant }
          sort &:full_name

          organise do
            group { |li| li.order }
            sort { |order| order.to_s }
          end
        end
    end

    columns do
      column { |lis| lis.first.order.bill_address.firstname + " " + lis.first.order.bill_address.lastname }
      column { |lis| lis.first.variant.product.name }
      column { |lis| lis.first.variant.product.group_buy ? (lis.first.variant.product.group_buy_unit_size || 0.0) : "" }
      column { |lis| lis.first.variant.full_name }
      column { |lis| lis.first.variant.weight || 0 }
      column { |lis| lis.sum { |li| li.quantity } }
      column { |lis| lis.sum { |li| li.max_quantity || 0 } }
      column { |lis| "" }
      column { |lis| "" }
    end
  end
end
