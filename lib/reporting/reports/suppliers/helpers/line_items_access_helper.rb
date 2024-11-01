# frozen_string_literal: true

module Reporting
  module Reports
    module Suppliers
      module Helpers
        module LineItemsAccessHelper
          def variant(line_item)
            line_item.variant
          end

          def order(line_item)
            line_item.order
          end

          def supplier(line_item)
            variant(line_item).supplier
          end

          def distributor(line_item)
            order(line_item).distributor
          end

          def item_order_cycle(line_item)
            line_item.order_cycle
          end

          def suppliers_adjustments(line_item, adjustment_type = 'EnterpriseFee')
            adjustments = line_item.adjustments
            return adjustments if adjustment_type == 'Spree::TaxRate'

            supplier_name = supplier(line_item).name
            adjustments.select do |adjustment|
              label = adjustment.label

              label.include?('supplier') && label.include?(supplier_name)
            end
          end

          def adjustments_by_type(line_item, type, included: false)
            total_amount = 0.0
            adjustment_type = type == :tax ? 'Spree::TaxRate' : 'EnterpriseFee'
            suppliers_adjustments(line_item, adjustment_type).each do |adjustment|
              if adjustment.originator_type == adjustment_type
                amount = included == adjustment.included ? adjustment.amount : 0.0
                total_amount += amount
              end
            end

            total_amount
          end

          def tax_on_fees(line_item, included: false)
            total_amount = 0.0
            suppliers_adjustments(line_item).each do |adjustment|
              next unless adjustment.originator_type == 'EnterpriseFee'

              adjustment.adjustments.each do |fee_adjustment|
                next unless fee_adjustment.originator_type == 'Spree::TaxRate'

                amount = included == fee_adjustment.included ? fee_adjustment.amount : 0.0
                total_amount += amount
              end
            end

            total_amount
          end
        end
      end
    end
  end
end
