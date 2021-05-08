# frozen_string_literal: false

# For #to_d method on Ruby 1.8
require 'bigdecimal/util'
require 'spree/localized_number'

module Calculator
  class PriceSack < Spree::Calculator
    extend Spree::LocalizedNumber

    preference :minimal_amount, :decimal, default: 0
    preference :normal_amount, :decimal, default: 0
    preference :discount_amount, :decimal, default: 0
    preference :currency, :string, default: Spree::Config[:currency]

    localize_number :preferred_minimal_amount,
                    :preferred_normal_amount,
                    :preferred_discount_amount

    def self.description
      I18n.t(:price_sack)
    end

    def compute(object)
      min = preferred_minimal_amount.to_f
      order_amount = line_items_for(object).map { |x| x.price * x.quantity }.sum

      if order_amount < min
        cost = preferred_normal_amount.to_f
      elsif order_amount >= min
        cost = preferred_discount_amount.to_f
      end

      cost
    end
  end
end
