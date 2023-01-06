# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
module Reporting
  module Reports
    module SalesTax
      class SalesTaxTotalsByOrder < Base
        def search
          report_line_items.orders
        end

        def order_permissions
          @order_permissions ||= ::Permissions::Order.new(user, ransack_params)
        end

        def report_line_items
          # Needed to filter by supplier_id
          @report_line_items ||= Reporting::LineItems.new(order_permissions, params)
        end

        def query_result
          # We'll group the line items by
          # [tax_rate_id, order_id]
          orders = report_line_items.list.map(&:order).uniq
          orders.flat_map(&join_tax_rate)
            .group_by(&group_key)
            .map(&change_root_to_order)
        end

        def join_tax_rate
          proc do |order|
            tax_rate_ids = order.all_adjustments.tax.pluck("distinct(originator_id)")
            tax_rate_ids << nil if tax_rate_ids.empty?
            tax_rate_ids.map do |tax_rate_id|
              {
                tax_rate_id: tax_rate_id,
                order: order
              }
            end
          end
        end

        def group_key
          proc do |hash|
            [
              hash[:tax_rate_id],
              hash[:order].id
            ]
          end
        end

        def change_root_to_order
          proc do |key, value|
            [key, value.first[:order]]
          end
        end

        def columns
          {
            distributor: :distributor,
            order_cycle: :order_cycle,
            order_number: :order_number,
            tax_category: :tax_category,
            tax_rate_name: :tax_rate_name,
            tax_rate: :tax_rate_amount,
            total_excl_tax: :total_excl_tax,
            tax: :tax_rate_total,
            total_incl_tax: :total_incl_tax,
            first_name: :first_name,
            last_name: :last_name,
            code: :code,
            email: :email,
          }
        end

        def columns_format
          {
            tax_rate: :percentage
          }
        end

        def rules
          [
            {
              group_by: :distributor,
            },
            {
              group_by: :order_cycle,
            },
            {
              group_by: :order_number,
              summary_row: proc do |_key, items, _rows|
                order = items.first.second
                {
                  total_excl_tax: order.total - order.total_tax,
                  tax: order.total_tax,
                  total_incl_tax: order.total,
                  first_name: order.customer&.first_name,
                  last_name: order.customer&.last_name,
                  code: order.customer&.code,
                  email: order.email
                }
              end
            }
          ]
        end

        def distributor(query_result_row)
          order(query_result_row).distributor&.name
        end

        def order_cycle(query_result_row)
          order(query_result_row).order_cycle&.name
        end

        def order_number(query_result_row)
          order(query_result_row).number
        end

        def tax_category(query_result_row)
          tax_rate(query_result_row)&.tax_category&.name
        end

        def tax_rate_name(query_result_row)
          tax_rate(query_result_row)&.name
        end

        def tax_rate_amount(query_result_row)
          tax_rate(query_result_row)&.amount
        end

        def total_excl_tax(query_result_row)
          order(query_result_row).total - order(query_result_row).total_tax
        end

        def tax_rate_total(query_result_row)
          order(query_result_row).all_adjustments
            .tax
            .where(originator_id: tax_rate_id(query_result_row))
            .pluck('sum(amount)').first || 0
        end

        def total_incl_tax(query_result_row)
          order(query_result_row).total -
            order(query_result_row).total_tax +
            tax_rate_total(query_result_row)
        end

        def first_name(query_result_row)
          order(query_result_row).customer&.first_name
        end

        def last_name(query_result_row)
          order(query_result_row).customer&.last_name
        end

        def code(query_result_row)
          order(query_result_row).customer&.code
        end

        def email(query_result_row)
          order(query_result_row).email
        end

        def tax_rate(query_result_row)
          targeted_tax_rate_id = tax_rate_id(query_result_row)
          tax_rates(query_result_row).find do |tax_rate|
            tax_rate.id == targeted_tax_rate_id
          end
        end

        def tax_rate_id(query_result_row)
          key(query_result_row).first
        end

        def tax_rates(query_result_row)
          order(query_result_row).all_adjustments
            .tax
            .select("distinct(originator_id)", "originator_type")
            .map(&:originator)
        end

        def key(query_result_row)
          query_result_row.first
        end

        def order(query_result_row)
          query_result_row.second
        end
      end
    end
  end
end
# rubocop:enable Metrics/ClassLength
