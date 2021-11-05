# frozen_string_literal: true

module Reporting
  module Reports
    module Packing
      class Customer < Base
        def select_fields
          lambda do
            {
              hub: default_blank(distributor_alias[:name]),
              customer_code: default_blank(masked(customer_table[:code])),
              first_name: default_blank(masked(bill_address_alias[:firstname])),
              last_name: default_blank(masked(bill_address_alias[:lastname])),
              supplier: default_blank(supplier_alias[:name]),
              product: default_string(product_table[:name], summary_row_title),
              variant: default_blank(variant_full_name),
              quantity: sum_values(line_item_table[:quantity]),
              temp_controlled: boolean_blank(shipping_category_table[:temperature_controlled]),
            }
          end
        end

        def ordering_fields
          lambda do
            [
              distributor_alias[:name],
              bill_address_alias[:lastname],
              order_table[:id],
              sql_grouping(grouping_fields),
              Arel.sql("supplier"),
              Arel.sql("product"),
              Arel.sql("variant"),
            ]
          end
        end

        def group_sets
          lambda do
            [
              distributor_alias[:name],
              bill_address_alias[:lastname],
              grouping_sets([parenthesise(order_table[:id]), parenthesise(grouping_fields)])
            ]
          end
        end
      end
    end
  end
end
