# frozen_string_literal: false

require_dependency 'spree/calculator'
require 'open_food_network/enterprise_fee_calculator'

module Calculator
  class DefaultTax < Spree::Calculator
    def self.description
      Spree.t(:default_tax)
    end

    # Default tax calculator still needs to support orders for legacy reasons
    # Orders created before Spree 2.1 had tax adjustments applied to the order, as a whole.
    # Orders created with Spree 2.2 and after, have them applied to the line items individually.
    def compute_order(order)
      matched_line_items = order.line_items.select do |line_item|
        line_item.tax_category == rate.tax_category
      end
      line_items_total = matched_line_items.sum(&:total)

      if rate.included_in_price
        round_to_two_places(line_items_total - ( line_items_total / (1 + rate.amount) ) )
      else
        round_to_two_places(line_items_total * rate.amount)
      end
    end

    def compute_adjustment(fee)
      if rate.included_in_price
        pre_tax_amount = fee.amount / (1 + rate.amount)
        deduced_total_by_rate(pre_tax_amount, rate)
      else
        round_to_two_places(fee.amount * rate.amount)
      end
    end

    def compute_shipment_or_line_item(item)
      pp "#compute_shipment" if item.is_a? Spree::Shipment

      # This can very nearly serve for adjustment adjustments as well...
      # The only difference is the item.pre_tax_amount, and it's possible we can sack it off anyway.
      # In that case we can rename it #compute_item and alias compute_shipment, compute_line_item,
      # and compute_adjustment to the same method
      if rate.included_in_price
        deduced_total_by_rate(item.pre_tax_amount, rate)
      else
        round_to_two_places(item.amount * rate.amount)
      end
    end
    alias_method :compute_shipment, :compute_shipment_or_line_item
    alias_method :compute_line_item, :compute_shipment_or_line_item

    def compute_shipping_rate(shipping_rate)
      if rate.included_in_price
        pre_tax_amount = shipping_rate.cost / (1 + rate.amount)
        if rate.zone == shipping_rate.shipment.order.tax_zone
          deduced_total_by_rate(pre_tax_amount, rate)
        else
          deduced_total_by_rate(pre_tax_amount, rate) * - 1
        end
      else
        with_tax_amount = shipping_rate.cost * rate.amount
        round_to_two_places(with_tax_amount)
      end
    end

    private

    def rate
      calculable
    end

    def line_items_total(order)
      matched_line_items = order.line_items.select do |line_item|
        line_item.product.tax_category == rate.tax_category
      end

      matched_line_items.sum(&:total)
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

    def round_to_two_places(amount)
      BigDecimal(amount.to_s).round(2, BigDecimal::ROUND_HALF_UP)
    end

    def deduced_total_by_rate(pre_tax_amount, rate)
      round_to_two_places(pre_tax_amount * rate.amount)
    end
  end
end
