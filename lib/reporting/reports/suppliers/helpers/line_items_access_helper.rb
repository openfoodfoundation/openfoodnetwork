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

          def adjustments_by_type(line_item, type, included: false)
            total_amount = 0.0
            adjustment_type = type == :tax ? 'Spree::TaxRate' : 'EnterpriseFee'
            adjustments = line_item.adjustments
            adjustments.each do |adjustment|
              if adjustment.originator_type == adjustment_type
                amount = included == adjustment.included ? adjustment.amount : 0.0
                total_amount += amount
              end
            end

            total_amount
          end

          def tax_on_fees(line_item, included: false)
            total_amount = 0.0
            adjustments = line_item.adjustments

            adjustments.each do |adjustment|
              next unless adjustment.originator_type == 'EnterpriseFee'

              adjustment.adjustments.each do |fee_adjustment|
                next unless adjustment.originator_type == 'Spree::TaxRate'

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
