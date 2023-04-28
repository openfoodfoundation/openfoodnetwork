# frozen_string_literal: false

module Calculator
  class PriceSack < Spree::Calculator
    preference :minimal_amount, :decimal, default: 0
    preference :normal_amount, :decimal, default: 0
    preference :discount_amount, :decimal, default: 0

    validates :preferred_minimal_amount,
              :preferred_normal_amount,
              :preferred_discount_amount,
              numericality: true

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
