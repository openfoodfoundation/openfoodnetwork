# frozen_string_literal: false

module Vouchers
  class PercentageRate < Voucher
    validates :amount,
              presence: true,
              numericality: { greater_than: 0, less_than_or_equal_to: 100 }

    def display_value
      ActionController::Base.helpers.number_to_percentage(amount, precision: 2)
    end

    def compute_amount(order)
      rate(order) * order.pre_discount_total
    end

    def rate(_order)
      -amount / 100
    end
  end
end
