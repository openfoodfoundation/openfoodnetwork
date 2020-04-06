require_dependency 'spree/calculator'
require 'spree/localized_number'

module Spree
  class Calculator::PerItem < Calculator
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
  end
end
