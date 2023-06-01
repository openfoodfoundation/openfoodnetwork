# frozen_string_literal: true

module Reporting
  module Reports
    module Packing
      class Base < ReportQueryTemplate
        def message
          I18n.t("spree.admin.reports.customer_names_message.customer_names_tip")
        end

        def report_query
          Queries::QueryBuilder.new(Spree::LineItem).
            scoped_to_orders(visible_orders_relation).
            scoped_to_line_items(ransacked_line_items_relation).
            with_managed_orders(managed_orders_relation).
            joins_order_and_distributor.
            joins_order_customer.
            joins_order_bill_address.
            joins_variant.
            joins_variant_product.
            joins_product_supplier.
            joins_product_shipping_category.
            selecting(select_fields).
            ordered_by(ordering_fields)
        end

        def columns_format
          { quantity: :quantity }
        end

        def default_params
          # Prevent breaking change in this report by hidding new columns by default
          { fields_to_hide: ["phone", "price"],
            q: {  order_completed_at_gt: 1.month.ago.beginning_of_day,
                  order_completed_at_lt: 1.day.from_now.beginning_of_day } }
        end

        private

        def select_fields # rubocop:disable Metrics/AbcSize
          lambda do
            {
              hub: distributor_alias[:name],
              customer_code: masked(customer_table[:code]),
              last_name: masked(bill_address_alias[:lastname]),
              first_name: masked(bill_address_alias[:firstname]),
              phone: masked(bill_address_alias[:phone]),
              supplier: supplier_alias[:name],
              product: product_table[:name],
              variant: variant_full_name,
              weight: line_item_table[:weight],
              height: line_item_table[:height],
              width: line_item_table[:width],
              depth: line_item_table[:depth],
              quantity: line_item_table[:quantity],
              price: (line_item_table[:quantity] * line_item_table[:price]),
              temp_controlled: shipping_category_table[:temperature_controlled],
            }
          end
        end

        def row_header(row)
          result = "#{row.last_name} #{row.first_name}"
          result += " (#{row.customer_code})" if row.customer_code
          result += " - #{row.phone}" if row.phone
          result
        end

        def summary_row
          proc do |_key, _items, rows|
            {
              quantity: rows.sum(&:quantity),
              price: rows.sum(&:price)
            }
          end
        end
      end
    end
  end
end
