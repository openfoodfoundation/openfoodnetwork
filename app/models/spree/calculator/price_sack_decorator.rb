require 'spree/localized_number'

module Spree
  Calculator::PriceSack.class_eval do
    extend Spree::LocalizedNumber

    localize_number :preferred_minimal_amount,
                    :preferred_normal_amount,
                    :preferred_discount_amount

    def self.description
      I18n.t(:price_sack)
    end

    def compute(object)
      min = self.preferred_minimal_amount.to_i
      order_amount = line_items_for(object).map { |x| x.price * x.quantity }.sum

      if order_amount < min
        cost = preferred_normal_amount
      elsif order_amount >= min
        cost = preferred_discount_amount
      end

      cost
    end
  end
end
