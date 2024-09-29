# frozen_string_literal: true

module Reporting
  module Reports
    module Suppliers
      class Base < ReportTemplate
        include Helpers::ColumnsHelper

        def default_params
          {
            q: {
              completed_at_gt: 1.month.ago.beginning_of_day,
              completed_at_lt: 1.day.from_now.beginning_of_day
            }
          }
        end

        def search
          report_line_items.orders
        end

        def query_result
          report_line_items.list(line_item_includes).group_by { |e|
            [e.variant_id, e.price, e.order.distributor_id]
          }.values
        end

        def columns
          {
            producer:,
            producer_address:,
            producer_abn_acn:,
            email:,
            hub:,
            hub_address:,
            hub_contact_email:,
            order_number:,
            order_date:,
            order_cycle:,
            order_cycle_start_date:,
            order_cycle_end_date:,
            product:,
            variant_unit_name:,
            quantity:,
            total_excl_vat_and_fees:,
            total_excl_vat:,
            total_fees_excl_vat:,
            total_vat_on_fees:,
            total_tax:,
            total:,
          }
        end

        def rules
          [
            {
              group_by: :producer,
              header: true,
              summary_row: proc do |_key, items|
                line_items = items.flatten

                {
                  total_excl_vat_and_fees: total_excl_vat_and_fees.call(line_items),
                  total_excl_vat: total_excl_vat.call(line_items),
                  total_fees_excl_vat: total_fees_excl_vat.call(line_items),
                  total_vat_on_fees: total_vat_on_fees.call(line_items),
                  total_tax: total_tax.call(line_items),
                  total: total.call(line_items),
                }
              end
            }
          ]
        end

        private

        def order_permissions
          return @order_permissions unless @order_permissions.nil?

          @order_permissions = ::Permissions::Order.new(@user, ransack_params)
        end

        def report_line_items
          @report_line_items ||= Reporting::LineItems.new(order_permissions, params)
        end

        def line_item_includes
          [{
            order: [
              :distributor,
              :adjustments,
              { shipments: { shipping_rates: :shipping_method } }
            ],
            variant: [:product, :supplier]
          }]
        end
      end
    end
  end
end
