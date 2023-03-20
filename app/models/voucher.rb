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

  private

  # For now voucher are only flat rate of 10
  def add_calculator
    self.calculator = Calculator::FlatRate.new(preferred_amount: -value)
  end
end
