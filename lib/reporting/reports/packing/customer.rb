# frozen_string_literal: true

module Reporting
  module Reports
    module Packing
      class Customer < Base
        def columns
          # Reorder default columns
          super.slice(:hub, :customer_code, :first_name, :last_name, :phone,
                      :supplier, :product, :variant, :weight, :height, :width, :depth, :quantity,
                      :price, :temp_controlled)
        end

        def rules
          [
            {
              group_by: :hub,
              header: true,
              header_class: "h1 with-background text-center",
            },
            {
              group_by: proc { |_item, row| row_header(row) },
              header: true,
              fields_used_in_header: [:first_name, :last_name, :customer_code, :phone],
              summary_row: summary_row,
            }
          ]
        end

        def ordering_fields
          lambda do
            [
              distributor_alias[:name],
              bill_address_alias[:lastname],
              order_table[:id],
              Arel.sql("supplier"),
              Arel.sql("product"),
              Arel.sql("variant"),
            ]
          end
        end
      end
    end
  end
end
