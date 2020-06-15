# frozen_string_literal: false

require_dependency 'spree/calculator'
require 'spree/localized_number'

module Spree
  module Calculator
    class PerItem < Calculator
      extend Spree::LocalizedNumber

      preference :amount, :decimal, default: 0
      preference :currency, :string, default: Spree::Config[:currency]

      localize_number :preferred_amount

      def self.description
        I18n.t(:flat_rate_per_item)
      end

      def compute(object = nil)
        return 0 if object.nil?

        number_of_line_items = line_items_for(object).reduce(0) do |sum, line_item|
          value_to_add = if matching_products.blank? || matching_products.include?(line_item.product)
                           line_item.quantity
                         else
                           0
                         end
          sum + value_to_add
        end
        preferred_amount * number_of_line_items
      end

      # Returns all products that match this calculator, but only if the calculator
      # is attached to a promotion. If attached to a ShippingMethod, nil is returned.
      def matching_products
        # Regression check for #1596
        # Calculator::PerItem can be used in two cases.
        # The first is in a typical promotion, providing a discount per item of a particular item
        # The second is a ShippingMethod, where it applies to an entire order
        #
        # Shipping methods do not have promotions attached, but promotions do
        # Therefore we must check for promotions
        if self.calculable.respond_to?(:promotion)
          self.calculable.promotion.rules.map do |rule|
            rule.respond_to?(:products) ? rule.products : []
          end.flatten
        end
      end
    end
  end
end
