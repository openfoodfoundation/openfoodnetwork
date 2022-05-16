# frozen_string_literal: true

module Reporting
  module Reports
    module SalesTax
      class TaxTypes < Base
        # rubocop:disable Metrics/AbcSize
        # rubocop:disable Rails/OutputSafety
        def columns
          {
            order_number: proc { |order| order_number_column(order).html_safe },
            date: proc { |order| order.completed_at },
            items: proc { |order| totals_of(order)[:items] },
            items_total: proc { |order| totals_of(order)[:items_total] },
            taxable_items_total: proc { |order| totals_of(order)[:taxable_total] },
            sales_tax: proc { |order| totals_of(order)[:sales_tax] },
            delivery_charge: proc { |order| order.shipments.first&.cost || 0.0 },
            tax_on_delivery: proc { |order| order.shipping_tax },
            tax_on_fees: proc { |order| order.enterprise_fee_tax },
            total_tax: proc { |order| order.total_tax },
            customer: proc { |order| order.bill_address.full_name },
            distributor: proc { |order| order.distributor&.name },
          }
        end
        # rubocop:enable Metrics/AbcSize
        # rubocop:enable Rails/OutputSafety

        private

        def totals_of(order)
          @totals ||= {}
          return @totals[order.id] if @totals[order.id].present?

          totals = { items: 0, items_total: 0.0, taxable_total: 0.0, sales_tax: 0.0 }

          order.line_items.each do |line_item|
            totals[:items] += line_item.quantity
            totals[:items_total] += line_item.amount

            sales_tax = tax_included_in line_item

            if sales_tax > 0
              totals[:taxable_total] += line_item.amount
              totals[:sales_tax] += sales_tax
            end
          end

          totals.each_pair do |k, _v|
            totals[k] = totals[k].round(2)
          end

          @totals[order.id] = totals
        end

        def tax_included_in(line_item)
          line_item.adjustments.tax.inclusive.sum(:amount)
        end
      end
    end
  end
end
