# frozen_string_literal: true

module Reporting
  module Reports
    module Suppliers
      module Helpers
        module ColumnsHelper
          include LineItemsAccessHelper

          def producer
            proc { |line_item| supplier(line_item).name }
          end

          def producer_address
            proc { |line_item| supplier(line_item).address&.full_address }
          end

          def producer_abn_acn
            proc do |line_items|
              supplier = supplier(line_items)
              # return nil if both abn and acn are nil so that it can be converted to "none"
              [supplier.abn, supplier.acn].compact_blank.join("/").presence
            end
          end

          def email
            proc { |line_item| supplier(line_item).email_address }
          end

          def hub
            proc { |line_item| distributor(line_item).name }
          end

          def hub_address
            proc { |line_item| distributor(line_item).address&.full_address }
          end

          def hub_contact_email
            proc { |line_item| distributor(line_item).email_address }
          end

          def order_number
            proc { |line_item| order(line_item).number }
          end

          def order_date
            proc { |line_item| order(line_item).completed_at.to_date }
          end

          def order_cycle
            proc { |line_item| item_order_cycle(line_item).name }
          end

          def order_cycle_start_date
            proc { |line_item| item_order_cycle(line_item).orders_open_at.to_date }
          end

          def order_cycle_end_date
            proc { |line_item| item_order_cycle(line_item).orders_close_at.to_date }
          end

          def product
            proc { |line_item| variant(line_item).product.name }
          end

          def variant_unit_name
            proc { |line_item| variant(line_item).full_name }
          end

          def quantity
            proc { |line_item| line_item.quantity }
          end

          def total_excl_fees_and_tax
            proc do |line_item|
              included_tax = adjustments_by_type(line_item, :tax, included: true)
              line_item.amount - included_tax
            end
          end

          def total_excl_vat
            proc do |line_item|
              total_fees = adjustments_by_type(line_item, :fees)
              total_excl_fees_and_tax.call(line_item) + total_fees
            end
          end

          def total_fees_excl_tax
            proc do |line_item|
              included_tax = tax_on_fees(line_item, included: true)
              adjustments_by_type(line_item, :fees) - included_tax
            end
          end

          def total_tax_on_fees
            proc { |line_item| tax_on_fees(line_item) + tax_on_fees(line_item, included: true) }
          end

          def total_tax
            proc do |line_item|
              excluded_tax = adjustments_by_type(line_item, :tax)
              included_tax = adjustments_by_type(line_item, :tax, included: true)

              excluded_tax + included_tax
            end
          end

          def total
            proc do |line_item|
              total_price = total_excl_fees_and_tax.call(line_item)
              total_fees = total_fees_excl_tax.call(line_item)
              total_fees_tax = total_tax_on_fees.call(line_item)
              tax = total_tax.call(line_item)

              total_price + total_fees + total_fees_tax + tax
            end
          end
        end
      end
    end
  end
end
