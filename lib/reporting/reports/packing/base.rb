# frozen_string_literal: true

module Reporting
  module Reports
    module Packing
      class Base < ReportTemplate
        SUBTYPES = ["customer", "supplier"]

        def primary_model
          Spree::LineItem
        end

        def report_query
          Queries::QueryBuilder.new(primary_model, grouping_fields).
            scoped_to_orders(scoped_orders_relation).
            scoped_to_line_items(visible_line_items_relation).
            with_managed_orders(managed_orders_relation).
            joins_order_and_distributor.
            joins_order_customer.
            joins_order_bill_address.
            joins_variant.
            joins_variant_product.
            joins_product_supplier.
            joins_product_shipping_category.
            join_line_item_option_values.
            selecting(select_fields).
            grouped_in_sets(group_sets).
            ordered_by(ordering_fields)
        end

        def grouping_fields
          lambda do
            [
              order_table[:id],
              line_item_table[:id]
            ]
          end
        end
      end
    end
  end
end
