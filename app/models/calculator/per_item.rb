# frozen_string_literal: false

require 'spree/localized_number'

module Calculator
  class PerItem < Spree::Calculator
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
        value_to_add = line_item.quantity
        sum + value_to_add
      end
      preferred_amount * number_of_line_items
    end
  end
end
