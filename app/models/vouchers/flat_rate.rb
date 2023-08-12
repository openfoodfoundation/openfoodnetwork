# frozen_string_literal: false

module Vouchers
  class FlatRate < Voucher
    validates :amount,
              presence: true,
              numericality: { greater_than: 0 }

    def display_value
      Spree::Money.new(amount)
    end

    # We limit adjustment to the maximum amount needed to cover the order, ie if the voucher
    # covers more than the order.total we only need to create an adjustment covering the order.total
    def compute_amount(order)
      -amount.clamp(0, order.pre_discount_total)
    end

    def rate(order)
      amount = compute_amount(order)

      amount / order.pre_discount_total
    end
  end
end
