# frozen_string_literal: false

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
      when Spree::Shipment, Spree::LineItem, Spree::Adjustment
        compute_item(computable)
      end
    end

    private

    def rate
      calculable
    end

    # Enable calculation of tax for enterprise fees with tax rates where included_in_price = false
    def compute_order(order)
      calculator = OpenFoodNetwork::EnterpriseFeeCalculator.new(order.distributor,
                                                                order.order_cycle)

      [
        line_items_total(order),
        shipments_total(order),
        per_item_fees_total(order, calculator),
        per_order_fees_total(order, calculator)
      ].sum do |total|
        round_to_two_places(total * rate.amount)
      end
    end

    def line_items_total(order)
      matched_line_items = order.line_items.select do |line_item|
        line_item.product.tax_category == rate.tax_category
      end

      matched_line_items.sum(&:total)
    end

    def shipments_total(order)
      order.shipments.select do |shipment|
        shipment.tax_category == rate.tax_category
      end.sum(&:cost)
    end

    # Finds relevant fees for each line_item,
    #   calculates the tax on them, and returns the total tax
    def per_item_fees_total(order, calculator)
      order.line_items.to_a.sum do |line_item|
        calculator.per_item_enterprise_fee_applicators_for(line_item.variant)
          .select { |applicator| applicable_rate?(applicator, line_item) }
          .sum { |applicator| applicator.enterprise_fee.compute_amount(line_item) }
      end
    end

    def applicable_rate?(applicator, line_item)
      fee = applicator.enterprise_fee
      (!fee.inherits_tax_category && fee.tax_category == rate.tax_category) ||
        (fee.inherits_tax_category && line_item.product.tax_category == rate.tax_category)
    end

    # Finds relevant fees for whole order,
    #   calculates the tax on them, and returns the total tax
    def per_order_fees_total(order, calculator)
      calculator.per_order_enterprise_fee_applicators_for(order)
        .select { |applicator| applicator.enterprise_fee.tax_category == rate.tax_category }
        .sum { |applicator| applicator.enterprise_fee.compute_amount(order) }
    end

    def compute_item(item)
      if rate.included_in_price
        deduced_total_by_rate(item.amount, rate)
      else
        round_to_two_places(item.amount * rate.amount)
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
