# frozen_string_literal: false

class Voucher < ApplicationRecord
  acts_as_paranoid

  include CalculatedAdjustments

  belongs_to :enterprise

  has_many :adjustments, as: :originator, class_name: 'Spree::Adjustment'

  validates :code, presence: true, uniqueness: { scope: :enterprise_id }

  before_validation :add_calculator

  def value
    10
  end

  def display_value
    Spree::Money.new(value)
  end

  # override the one from CalculatedAdjustments so we limit adjustment to the maximum amount
  # needed to cover the order, ie if the voucher covers more than the order.total we only need
  # to create a adjustment covering the order.total
  # Doesn't work with taxes for now
  def compute_amount(order)
    amount = calculator.compute(order)

    return -order.total if amount.abs > order.total

    amount
  end

  private

  # For now voucher are only flat rate of 10
  def add_calculator
    self.calculator = Calculator::FlatRate.new(preferred_amount: -value)
  end
end
