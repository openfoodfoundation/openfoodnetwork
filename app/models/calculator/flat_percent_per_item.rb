# frozen_string_literal: true

class Calculator::FlatPercentPerItem < Spree::Calculator
  # Spree's FlatPercentItemTotal calculator sums all amounts, and then calculates a percentage
  # on them.
  # In the cart, we display line item individual amounts rounded, so to have consistent
  # calculations we do the same internally. Here, we round adjustments at the individual
  # item level first, then multiply by the item quantity.
  preference :flat_percent, :decimal, default: 0

  validates :preferred_flat_percent,
            numericality: true

  def self.description
    I18n.t(:flat_percent_per_item)
  end

  def compute(object)
    line_items_for(object).to_a.sum do |li|
      unless li.price.present? && li.quantity.present?
        raise ArgumentError, "object must respond to #price and #quantity"
      end

      value = (li.price * BigDecimal(preferred_flat_percent.to_s) / 100.0).round(2)
      value * li.quantity
    end
  end
end
