# frozen_string_literal: true

module Reporting
  module Reports
    module Packing
      class Supplier < Base
        # rubocop:disable Metrics/AbcSize
        def select_fields
          lambda do
            {
              hub: default_blank(distributor_alias[:name]),
              supplier: default_blank(supplier_alias[:name]),
              customer_code: default_blank(customer_table[:code]),
              last_name: default_blank(masked(bill_address_alias[:lastname])),
              first_name: default_blank(masked(bill_address_alias[:firstname])),
              product: default_string(product_table[:name], summary_row_title),
              variant: default_blank(variant_full_name),
              quantity: sum_values(line_item_table[:quantity]),
              price: sum_values(line_item_table[:quantity] * line_item_table[:price]),
              temp_controlled: boolean_blank(shipping_category_table[:temperature_controlled]),
            }
          end
        end
        # rubocop:enable Metrics/AbcSize

        def group_sets
          lambda do
            [
              distributor_alias[:name],
              supplier_alias[:name],
              grouping_sets([parenthesise(supplier_alias[:name]), parenthesise(grouping_fields)])
            ]
          end
        end

        def ordering_fields
          lambda do
            [
              distributor_alias[:name],
              supplier_alias[:name],
              sql_grouping(grouping_fields),
              Arel.sql("product"),
              Arel.sql("variant"),
              Arel.sql("last_name")
            ]
          end
        end
      end
    end
  end
end
