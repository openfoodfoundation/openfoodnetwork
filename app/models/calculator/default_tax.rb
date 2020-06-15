# frozen_string_literal: false

require_dependency 'spree/calculator'
require 'open_food_network/enterprise_fee_calculator'

module Calculator
  class DefaultTax < Spree::Calculator
    def self.description
      Spree.t(:default_tax)
    end

    def compute(computable)
      case computable
      when Spree::Order
        compute_order(computable)
      when Spree::LineItem
        compute_line_item(computable)
      end
    end

    private

    def rate
      calculable
    end

    # Enable calculation of tax for enterprise fees with tax rates where included_in_price = false
    def compute_order(order)
      matched_line_items = order.line_items.select do |line_item|
        line_item.product.tax_category == rate.tax_category
      end

      line_items_total = matched_line_items.sum(&:total)

      calculator = OpenFoodNetwork::EnterpriseFeeCalculator.new(order.distributor,
                                                                order.order_cycle)

      # Finds relevant fees for each line_item,
      #   calculates the tax on them, and returns the total tax
      per_item_fees_total = order.line_items.sum do |line_item|
        calculator.per_item_enterprise_fee_applicators_for(line_item.variant)
          .select { |applicator|
            (!applicator.enterprise_fee.inherits_tax_category &&
              applicator.enterprise_fee.tax_category == rate.tax_category) ||
              (applicator.enterprise_fee.inherits_tax_category &&
               line_item.product.tax_category == rate.tax_category)
          }
          .sum { |applicator| applicator.enterprise_fee.compute_amount(line_item) }
      end

      # Finds relevant fees for whole order,
      #   calculates the tax on them, and returns the total tax
      per_order_fees_total = calculator.per_order_enterprise_fee_applicators_for(order)
        .select { |applicator| applicator.enterprise_fee.tax_category == rate.tax_category }
        .sum { |applicator| applicator.enterprise_fee.compute_amount(order) }

      [line_items_total, per_item_fees_total, per_order_fees_total].sum do |total|
        round_to_two_places(total * rate.amount)
      end
    end

    def compute_line_item(line_item)
      if line_item.tax_category == rate.tax_category
        if rate.included_in_price
          deduced_total_by_rate(line_item.total, rate)
        else
          round_to_two_places(line_item.total * rate.amount)
        end
      else
        0
      end
    end

    def round_to_two_places(amount)
      BigDecimal(amount.to_s).round(2, BigDecimal::ROUND_HALF_UP)
    end

    def deduced_total_by_rate(total, rate)
      round_to_two_places(total - ( total / (1 + rate.amount) ) )
    end
  end
end
