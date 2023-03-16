# frozen_string_literal: false

require 'spree/localized_number'

module Calculator
  class PerItem < Spree::Calculator
    extend Spree::LocalizedNumber

    preference :amount, :decimal, default: 0

    localize_number :preferred_amount

    validates :preferred_amount,
              numericality: { message: :calculator_preferred_value_error },
              unless: -> { Spree::Config.enable_localized_number? }

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
