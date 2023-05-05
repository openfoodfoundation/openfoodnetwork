# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
module Reporting
  module Reports
    module OrdersAndFulfillment
      class OrderCycleCustomerTotals < Base
        # rubocop:disable Metrics/AbcSize
        # rubocop:disable Metrics/MethodLength
        # rubocop:disable Metrics/PerceivedComplexity
        # rubocop:disable Metrics/CyclomaticComplexity
        # rubocop:disable Naming/VariableNumber
        def columns
          {
            hub: hub_name,
            customer: proc { |line_items|
              bill_address = bill_address(line_items)
              "#{bill_address&.firstname} #{bill_address&.lastname}"
            },
            email: proc { |line_items| line_items.first.order.email },
            phone: proc { |line_items| bill_address(line_items)&.phone },
            producer: supplier_name,
            product: product_name,
            variant: variant_name,

            quantity: proc { |line_items| line_items.to_a.sum(&:quantity) },
            item_price: proc { |line_items| line_items.sum(&:amount) },
            item_fees_price: proc { |line_items| line_items.sum(&:amount_with_adjustments) },
            admin_handling_fees: proc { |_line_items| "" },
            ship_price: proc { |_line_items| "" },
            pay_fee_price: proc { |_line_items| "" },
            total_price: proc { |_line_items| "" },
            paid: proc { |line_items| line_items.all? { |li| li.order.paid? } },

            shipping: proc { |line_items| shipping_method(line_items)&.name },
            delivery: proc { |line_items| delivery?(line_items) },

            ship_street: proc { |line_items| ship_address(line_items)&.address1 },
            ship_street_2: proc { |line_items| ship_address(line_items)&.address2 },
            ship_city: proc { |line_items| ship_address(line_items)&.city },
            ship_postcode: proc { |line_items| ship_address(line_items)&.zipcode },
            ship_state: proc { |line_items| ship_address(line_items)&.state },

            comments: proc { |_line_items| "" },
            sku: proc do |line_items|
              line_item = line_items.first
              variant_scoper_for(line_item.order.distributor_id).scope(line_item.variant)
              line_item.variant.sku
            end,

            order_cycle: proc { |line_items| line_items.first.order.order_cycle&.name },
            payment_method: proc { |line_items|
              payment = line_items.first.order.payments.first
              payment&.payment_method&.name
            },
            customer_code: proc { |line_items| distributor_customer(line_items)&.code },
            tags: proc { |line_items| distributor_customer(line_items)&.tags&.join(', ') },

            billing_street: proc { |line_items| bill_address(line_items)&.address1 },
            billing_street_2: proc { |line_items| bill_address(line_items)&.address2 },
            billing_city: proc { |line_items| bill_address(line_items)&.city },
            billing_postcode: proc { |line_items| bill_address(line_items)&.zipcode },
            billing_state: proc { |line_items| bill_address(line_items)&.state },

            order_number: proc { |line_items| line_items.first.order.number },
            date: proc { |line_items| line_items.first.order.completed_at.strftime("%F %T") },
            final_weight_volume: proc { |line_items| line_items.sum(&:final_weight_volume) },
          }
        end
        # rubocop:enable Metrics/AbcSize
        # rubocop:enable Metrics/MethodLength
        # rubocop:enable Metrics/PerceivedComplexity
        # rubocop:enable Metrics/CyclomaticComplexity
        # rubocop:enable Naming/VariableNumber

        def rules
          [
            {
              group_by: :hub,
              header: proc { |key, _items, _rows| "#{I18n.t(:report_header_hub)} #{key}" },
              header_class: "h1",
            },
            {
              group_by: proc { |line_items, _row| line_items.first.order },
              sort_by: proc { |order| order.bill_address.full_name_reverse.downcase },
              header: proc { |_order, _items, rows| row_header(rows.first) },
              fields_used_in_header: [:customer, :email, :phone, :order_cycle, :order_number],
              summary_row: proc { |order, _grouped_line_items, rows| summary_row(order, rows) }
            },
          ]
        end

        def line_item_includes
          [{ variant: { product: :supplier },
             order: [:bill_address, :ship_address, :order_cycle, :adjustments, :payments,
                     :user, :distributor, :shipments] }]
        end

        def query_result
          report_line_items.list(line_item_includes).group_by { |e|
            [e.variant_id, e.price, e.order_id]
          }.values
        end

        def default_params
          super.merge(
            {
              fields_to_hide: [:final_weight_volume]
            }
          )
        end

        private

        def row_header(row)
          result = row.customer
          result += " - #{row.email}" if row.email
          result += " - #{row.phone}" if row.phone
          result += " | #{row.order_cycle} (#{row.order_number})"
          result
        end

        def summary_row(order, rows)
          {
            hub: rows.last.hub,
            customer: rows.last.customer,
            item_price: rows.sum(&:item_price),
            item_fees_price: rows.sum(&:item_fees_price),
            admin_handling_fees: order.admin_and_handling_total,
            ship_price: order.ship_total,
            pay_fee_price: order.payment_fee,
            total_price: order.total,
            paid: order.paid?,
            comments: order.special_instructions,
            order_cycle: order.order_cycle&.name,
            payment_method: order.payments.first&.payment_method&.name,
            order_number: order.number,
            date: order.completed_at.strftime("%F %T"),
          }
        end

        def shipping_method(line_items)
          return unless shipping_rates = line_items.first.order.shipments.first&.shipping_rates

          shipping_rate = shipping_rates.find(&:selected) || shipping_rates.first
          shipping_rate.try(:shipping_method)
        end

        def delivery?(line_items)
          shipping_method(line_items)&.delivery?
        end

        def ship_address(line_items)
          line_items.first.order.ship_address if delivery?(line_items)
        end

        def bill_address(line_items)
          line_items.first.order.bill_address
        end

        def distributor_customer(line_items)
          distributor = line_items.first.order.distributor
          user = line_items.first.order.user
          user&.customer_of(distributor)
        end
      end
    end
  end
end
# rubocop:enable Metrics/ClassLength
