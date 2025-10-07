# frozen_string_literal: true

module Reporting
  module Reports
    module Packing
      class Base < ReportQueryTemplate
        def message
          I18n.t("spree.admin.reports.hidden_customer_details_tip")
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
            joins_variant_supplier.
            joins_variant_shipping_category.
            joins_selected_shipping_methods.
            selecting(select_fields).
            ordered_by(ordering_fields)
        end

        def columns_format
          { quantity: :quantity }
        end

        def default_params
          # Prevent breaking change in this report by hidding new columns by default
          { fields_to_hide: ["phone", "price", "shipment_state", "shipping_method"],
            q: {  order_completed_at_gt: 1.month.ago.beginning_of_day,
                  order_completed_at_lt: 1.day.from_now.beginning_of_day } }
        end

        private

        def select_fields # rubocop:disable Metrics/AbcSize
          lambda do
            {
              hub: distributor_alias[:name],
              customer_code: mask_customer_name(customer_table[:code]),
              last_name: mask_customer_name(bill_address_alias[:lastname]),
              first_name: mask_customer_name(bill_address_alias[:firstname]),
              phone: mask_contact_data(bill_address_alias[:phone]),
              supplier: supplier_alias[:name],
              product: product_table[:name],
              variant: variant_full_name,
              weight: line_item_table[:weight],
              height: line_item_table[:height],
              width: line_item_table[:width],
              depth: line_item_table[:depth],
              quantity: line_item_table[:quantity],
              price: (line_item_table[:quantity] * line_item_table[:price]),
              shipment_state: order_table[:shipment_state],
              shipping_method: shipping_method_table[:name],
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
              quantity: rows.map(&:quantity).sum(&:to_i),
              price: rows.map(&:price).sum(&:to_f)
            }
          end
        end
      end
    end
  end
end
