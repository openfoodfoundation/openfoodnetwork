# frozen_string_literal: true

module Reporting
  module Reports
    module Suppliers
      module Helpers
        module ColumnsHelper
          include LineItemsAccessHelper

          def producer
            proc { |line_items| supplier(line_items).name }
          end

          def producer_address
            proc { |line_items| supplier(line_items).address&.full_address }
          end

          def producer_abn_acn
            proc do |line_items|
              supplier = supplier(line_items)

              [supplier.abn, supplier.acn].compact_blank.join("/")
            end
          end

          def email
            proc { |line_items| supplier(line_items).email_address }
          end

          def hub
            proc { |line_items| distributor(line_items).name }
          end

          def hub_address
            proc { |line_items| distributor(line_items).address&.full_address }
          end

          def hub_contact_email
            proc { |line_items| distributor(line_items).email_address }
          end

          def order_number
            proc { |line_items| order(line_items).number }
          end

          def order_date
            proc { |line_items| order(line_items).completed_at.strftime("%d/%m/%Y") }
          end

          def order_cycle
            proc { |line_items| item_order_cycle(line_items).name }
          end

          def order_cycle_start_date
            proc { |line_items| item_order_cycle(line_items).orders_open_at.strftime("%d/%m/%Y") }
          end

          def order_cycle_end_date
            proc { |line_items| item_order_cycle(line_items).orders_close_at.strftime("%d/%m/%Y") }
          end

          def product
            proc { |line_items| variant(line_items).product.name }
          end

          def variant_unit_name
            proc { |line_items| variant(line_items).full_name }
          end

          def quantity
            proc { |line_items| line_items.to_a.sum(&:quantity) }
          end

          def total_excl_vat_and_fees
            proc do |line_items|
              included_tax = adjustments_by_type(line_items, :tax, included: true)
              line_items.sum(&:amount) - included_tax
            end
          end

          def total_excl_vat
            proc do |line_items|
              total_fees = adjustments_by_type(line_items, :fees)
              total_excl_vat_and_fees.call(line_items) + total_fees
            end
          end

          def total_fees_excl_vat
            proc do |line_items|
              included_tax = tax_on_fees(line_items, included: true)
              adjustments_by_type(line_items, :fees) - included_tax
            end
          end

          def total_vat_on_fees
            proc { |line_items| tax_on_fees(line_items) }
          end

          def total_tax
            proc do |line_items|
              excluded_tax = adjustments_by_type(line_items, :tax)
              included_tax = adjustments_by_type(line_items, :tax, included: true)

              excluded_tax + included_tax
            end
          end

          def total
            proc do |line_items|
              total_price = total_excl_vat_and_fees.call(line_items)
              total_fees = total_fees_excl_vat.call(line_items)
              tax = total_tax.call(line_items)

              total_price + total_fees + tax
            end
          end
        end
      end
    end
  end
end
