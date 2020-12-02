# frozen_string_literal: false

require_dependency 'spree/calculator'
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
      #order_amount = line_items_for(object).map { |x| x.price * x.quantity }.sum

      amount = if object.is_a?(Array)
                 object.map { |o| o.respond_to?(:amount) ? o.amount : BigDecimal(o.to_s) }.sum
               else
                 object.respond_to?(:amount) ? object.amount : BigDecimal(object.to_s)
               end

      cost = if amount < preferred_minimal_amount.to_f
               preferred_normal_amount.to_f
             else
               preferred_discount_amount.to_f
             end

      cost
    end
  end
end
