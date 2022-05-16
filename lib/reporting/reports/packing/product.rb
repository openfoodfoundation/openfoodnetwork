# frozen_string_literal: true

module Reporting
  module Reports
    module Packing
      class Product < Base
        def columns
          # Reorder default columns
          super.slice(:hub, :supplier, :product, :variant,
                      :customer_code, :first_name, :last_name, :phone,
                      :quantity, :price, :temp_controlled)
        end

        def rules
          [
            {
              group_by: :hub,
              header: true,
              header_class: "h1 with-background text-center",
            },
            {
              group_by: :supplier,
              header: true,
              header_class: "h1",
            },
            {
              group_by: proc { |_item, row| "#{row.product} - #{row.variant}" },
              header: true,
              fields_used_in_header: [:product, :variant],
              summary_row: summary_row,
              header_class: "h3",
            }
          ]
        end

        def ordering_fields
          lambda do
            [
              distributor_alias[:name],
              Arel.sql("supplier"),
              Arel.sql("product"),
              Arel.sql("variant"),
              bill_address_alias[:lastname],
              order_table[:id],
            ]
          end
        end
      end
    end
  end
end
