# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
module Reporting
  module Reports
    module SalesTax
      class SalesTaxTotalsByProducer < Base
        def search
          report_line_items.orders
        end

        def order_permissions
          return @order_permissions unless @order_permissions.nil?

          @order_permissions = ::Permissions::Order.new(user, ransack_params)
        end

        def report_line_items
          @report_line_items ||= Reporting::LineItems.new(order_permissions, params)
        end

        def query_result
          # The objective is to group the line items by
          # [tax_rate, supplier_id, distributor_id and order_cycle_id]
          report_line_items.list
            .flat_map do |line_item|
              line_item.tax_rates.map do |tax_rate|
                {
                  tax_rate_id: tax_rate.id,
                  line_item: line_item
                }
              end
            end.group_by do |hash|
            [
              hash[:tax_rate_id],
              hash[:line_item].supplier_id,
              hash[:line_item].order.distributor_id,
              hash[:line_item].order.order_cycle_id
            ]
          end.each do |_, v|
            v.map!{ |item| item[:line_item] }
          end
        end

        def columns
          {
            distributor: :distributor,
            distributor_tax_status: :distributor_tax_status,
            producer: :producer,
            producer_tax_status: :producer_tax_status,
            order_cycle: :order_cycle,
            tax_category: :tax_category,
            tax_rate_name: :tax_rate_name,
            tax_rate: :tax_rate_amount,
            total_excl_tax: :total_excl_tax,
            tax: :tax,
            total_incl_tax: :total_incl_tax
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
              group_by: :producer,
            },
            {
              group_by: :order_cycle,
              summary_row: proc do |_key, items, _rows|
                line_items = items.flat_map(&:second).flatten.uniq
                total_excl_tax = line_items.sum(&:amount) - line_items.sum(&:included_tax)
                tax = line_items.map do |line_item|
                  line_item.adjustments.eligible.tax.sum(&:amount)
                end.sum
                {
                  total_excl_tax: total_excl_tax,
                  tax: tax,
                  total_incl_tax: total_excl_tax + tax
                }
              end
            }
          ]
        end

        protected

        def distributor(query_result_row)
          first_line_item(query_result_row).order.distributor&.name
        end

        def distributor_tax_status(query_result_row)
          first_line_item(query_result_row).order.distributor&.charges_sales_tax
        end

        def producer(query_result_row)
          first_line_item(query_result_row).supplier.name
        end

        def producer_tax_status(query_result_row)
          first_line_item(query_result_row).supplier.charges_sales_tax
        end

        def order_cycle(query_result_row)
          first_line_item(query_result_row).order_cycle&.name
        end

        def tax_category(query_result_row)
          first_line_item(query_result_row).tax_category&.name
        end

        def tax_rate_name(query_result_row)
          tax_rate(query_result_row)&.name
        end

        def tax_rate_amount(query_result_row)
          tax_rate(query_result_row)&.amount
        end

        def total_excl_tax(query_result_row)
          line_items(query_result_row).sum(&:amount) -
            line_items(query_result_row).sum(&:included_tax)
        end

        def tax(query_result_row)
          line_items(query_result_row)&.map do |line_item|
            line_item.adjustments.eligible.tax
              .where(originator_id: tax_rate_id(query_result_row))
              .sum(&:amount)
          end&.sum
        end

        def total_incl_tax(query_result_row)
          total_excl_tax(query_result_row) + tax(query_result_row)
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
          first_line_item(query_result_row).tax_rates
        end

        def key(query_result_row)
          query_result_row.first
        end

        def first_line_item(query_result_row)
          line_items(query_result_row).first
        end

        def line_items(query_result_row)
          query_result_row.second
        end
      end
    end
  end
end
# rubocop:enable Metrics/ClassLength
