# frozen_string_literal: true

module Reporting
  module Reports
    module Packing
      class Supplier < Base
        def columns
          # Reorder default columns
          super.slice(:hub, :supplier, :customer_code, :first_name, :last_name, :phone,
                      :product, :variant, :quantity, :price, :temp_controlled)
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
              summary_row: summary_row,
              summary_row_label: I18n.t('admin.reports.total_by_supplier').upcase
            },
            {
              group_by: proc { |_item, row| row_header(row) },
              header: true,
              header_class: 'h4',
              fields_used_in_header: [:first_name, :last_name, :customer_code, :phone],
              summary_row: summary_row,
              summary_row_class: "",
              summary_row_label: I18n.t('admin.reports.total_by_customer')
            }
          ]
        end

        def ordering_fields
          lambda do
            [
              distributor_alias[:name],
              supplier_alias[:name],
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
