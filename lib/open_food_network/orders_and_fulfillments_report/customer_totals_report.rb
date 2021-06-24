# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
module OpenFoodNetwork
  class OrdersAndFulfillmentsReport
    class CustomerTotalsReport
      REPORT_TYPE = "order_cycle_customer_totals"

      attr_reader :context

      delegate :line_item_name, to: :context
      delegate :variant_scoper_for, to: :context

      def initialize(context)
        @context = context
        @scopers_by_distributor_id = {}
      end

      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/MethodLength
      def header
        [I18n.t(:report_header_hub), I18n.t(:report_header_customer), I18n.t(:report_header_email),
         I18n.t(:report_header_phone), I18n.t(:report_header_producer),
         I18n.t(:report_header_product), I18n.t(:report_header_variant),
         I18n.t(:report_header_quantity),
         I18n.t(:report_header_item_price, currency: currency_symbol),
         I18n.t(:report_header_item_fees_price, currency: currency_symbol),
         I18n.t(:report_header_admin_handling_fees, currency: currency_symbol),
         I18n.t(:report_header_ship_price, currency: currency_symbol),
         I18n.t(:report_header_pay_fee_price, currency: currency_symbol),
         I18n.t(:report_header_total_price, currency: currency_symbol),
         I18n.t(:report_header_paid), I18n.t(:report_header_shipping),
         I18n.t(:report_header_delivery), I18n.t(:report_header_ship_street),
         I18n.t(:report_header_ship_street_2), I18n.t(:report_header_ship_city),
         I18n.t(:report_header_ship_postcode), I18n.t(:report_header_ship_state),
         I18n.t(:report_header_comments), I18n.t(:report_header_sku),
         I18n.t(:report_header_order_cycle), I18n.t(:report_header_payment_method),
         I18n.t(:report_header_customer_code), I18n.t(:report_header_tags),
         I18n.t(:report_header_billing_street), I18n.t(:report_header_billing_street_2),
         I18n.t(:report_header_billing_city), I18n.t(:report_header_billing_postcode),
         I18n.t(:report_header_billing_state),
         I18n.t(:report_header_order_number),
         I18n.t(:report_header_date)]
      end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/MethodLength

      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/MethodLength
      def rules
        [
          {
            group_by: proc { |line_item| line_item.order.distributor },
            sort_by: proc { |distributor| distributor.name }
          },
          {
            group_by: proc { |line_item| line_item.order },
            sort_by: proc { |order| order.bill_address.full_name_reverse },
            summary_columns: [
              proc { |line_items| line_items.first.order.distributor.name },
              proc { |line_items| line_items.first.order.bill_address.full_name },
              proc { |_line_items| "" },
              proc { |_line_items| "" },
              proc { |_line_items| "" },
              proc { |_line_items| I18n.t('admin.reports.total') },
              proc { |_line_items| "" },

              proc { |_line_items| "" },
              proc { |line_items| line_items.sum(&:amount) },
              proc { |line_items| line_items.sum(&:amount_with_adjustments) },
              proc { |line_items| line_items.first.order.admin_and_handling_total },
              proc { |line_items| line_items.first.order.ship_total },
              proc { |line_items| line_items.first.order.payment_fee },
              proc { |line_items| line_items.first.order.total },
              proc { |line_items| line_items.first.order.paid? ? I18n.t(:yes) : I18n.t(:no) },

              proc { |_line_items| "" },
              proc { |_line_items| "" },

              proc { |_line_items| "" },
              proc { |_line_items| "" },
              proc { |_line_items| "" },
              proc { |_line_items| "" },
              proc { |_line_items| "" },

              proc { |line_items| line_items.first.order.special_instructions },
              proc { |_line_items| "" },

              proc { |line_items| line_items.first.order.order_cycle.andand.name },
              proc { |line_items|
                line_items.first.order.payments.first.andand.payment_method.andand.name
              },
              proc { |_line_items| "" },
              proc { |_line_items| "" },
              proc { |_line_items| "" },
              proc { |_line_items| "" },
              proc { |_line_items| "" },
              proc { |_line_items| "" },
              proc { |_line_items| "" },
              proc { |line_items| line_items.first.order.number },
              proc { |line_items| line_items.first.order.completed_at.strftime("%F %T") },
            ]
          },
          {
            group_by: proc { |line_item| line_item.variant.product },
            sort_by: proc { |product| product.name }
          },
          {
            group_by: proc { |line_item| line_item.variant },
            sort_by: proc { |variant| variant.full_name }
          },
          {
            group_by: line_item_name,
            sort_by: proc { |full_name| full_name }
          }
        ]
      end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/MethodLength

      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/MethodLength
      # rubocop:disable Metrics/PerceivedComplexity
      def columns
        rsa = proc { |line_items| shipping_method(line_items).andand.delivery? }
        [
          proc { |line_items| line_items.first.order.distributor.name },
          proc { |line_items|
            bill_address = line_items.first.order.bill_address
            bill_address.firstname + " " + bill_address.lastname
          },
          proc { |line_items| line_items.first.order.email },
          proc { |line_items| line_items.first.order.bill_address.phone },
          proc { |line_items| line_items.first.variant.product.supplier.name },
          proc { |line_items| line_items.first.variant.product.name },
          proc { |line_items| line_items.first.variant.full_name },

          proc { |line_items| line_items.to_a.sum(&:quantity) },
          proc { |line_items| line_items.sum(&:amount) },
          proc { |line_items| line_items.sum(&:amount_with_adjustments) },
          proc { |_line_items| "" },
          proc { |_line_items| "" },
          proc { |_line_items| "" },
          proc { |_line_items| "" },
          proc { |line_items|
            line_items.all? { |li| li.order.paid? } ? I18n.t(:yes) : I18n.t(:no)
          },

          proc { |line_items| shipping_method(line_items).andand.name },
          proc { |line_items| rsa.call(line_items) ? I18n.t(:yes) : I18n.t(:no) },

          proc { |line_items|
            line_items.first.order.ship_address.andand.address1 if rsa.call(line_items)
          },
          proc { |line_items|
            line_items.first.order.ship_address.andand.address2 if rsa.call(line_items)
          },
          proc { |line_items|
            line_items.first.order.ship_address.andand.city if rsa.call(line_items)
          },
          proc { |line_items|
            line_items.first.order.ship_address.andand.zipcode if rsa.call(line_items)
          },
          proc { |line_items|
            line_items.first.order.ship_address.andand.state if rsa.call(line_items)
          },

          proc { |_line_items| "" },
          proc do |line_items|
            line_item = line_items.first
            variant_scoper_for(line_item.order.distributor_id).scope(line_item.variant)
            line_item.variant.sku
          end,

          proc { |line_items| line_items.first.order.order_cycle.andand.name },
          proc { |line_items|
            payment = line_items.first.order.payments.first
            payment.andand.payment_method.andand.name
          },
          proc { |line_items|
            distributor = line_items.first.order.distributor
            user = line_items.first.order.user
            user.andand.customer_of(distributor).andand.code
          },
          proc { |line_items|
            distributor = line_items.first.order.distributor
            user = line_items.first.order.user
            user.andand.customer_of(distributor).andand.tags.andand.join(', ')
          },

          proc { |line_items| line_items.first.order.bill_address.andand.address1 },
          proc { |line_items| line_items.first.order.bill_address.andand.address2 },
          proc { |line_items| line_items.first.order.bill_address.andand.city },
          proc { |line_items| line_items.first.order.bill_address.andand.zipcode },
          proc { |line_items| line_items.first.order.bill_address.andand.state },
          proc { |line_items| line_items.first.order.number },
          proc { |line_items| line_items.first.order.completed_at.strftime("%F %T") },
        ]
      end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/PerceivedComplexity

      def line_item_includes
        [{ variant: [{ option_values: :option_type }, { product: :supplier }],
           order: [:bill_address, :ship_address, :order_cycle, :adjustments, :payments,
                   :user, :distributor, :shipments] }]
      end

      private

      def shipping_method(line_items)
        shipping_rates = line_items.first.order.shipments.first.
          andand.shipping_rates

        return unless shipping_rates

        shipping_rate = shipping_rates.find(&:selected) || shipping_rates.first
        shipping_rate.try(:shipping_method)
      end
    end
  end
end
# rubocop:enable Metrics/ClassLength
