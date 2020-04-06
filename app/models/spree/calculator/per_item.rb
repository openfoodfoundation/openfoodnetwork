require_dependency 'spree/calculator'

module Spree
  class Calculator::PerItem < Calculator
    preference :amount, :decimal, default: 0
    preference :currency, :string, default: Spree::Config[:currency]

    def self.description
      Spree.t(:flat_rate_per_item)
    end

    def compute(object=nil)
      return 0 if object.nil?
      self.preferred_amount * object.line_items.reduce(0) do |sum, value|
        value_to_add = value.quantity
        sum + value_to_add
      end
    end
  end
end
