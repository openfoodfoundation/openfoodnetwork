# frozen_string_literal: false

class Voucher < ApplicationRecord
  acts_as_paranoid

  belongs_to :enterprise

  has_many :adjustments,
           as: :originator,
           class_name: 'Spree::Adjustment',
           inverse_of: :voucher,
           dependent: :nullify

  validates :code, presence: true, uniqueness: { scope: :enterprise_id }

  def value
    10
  end

  def display_value
    Spree::Money.new(value)
  end

  # Ideally we would use `include CalculatedAdjustments` to be consistent with other adjustments,
  # but vouchers have complicated calculation so we can't easily use Spree::Calculator. We keep
  # the same method to stay as consistent as possible.
  #
  # Creates a new voucher adjustment for the given order
  def create_adjustment(label, order)
    amount = compute_amount(order)

    adjustment_attributes = {
      amount: amount,
      originator: self,
      order: order,
      label: label,
      mandatory: false,
      state: "open",
      tax_category: nil
    }

    order.adjustments.create(adjustment_attributes)
  end

  # We limit adjustment to the maximum amount needed to cover the order, ie if the voucher
  # covers more than the order.total we only need to create an adjustment covering the order.total
  def compute_amount(order)
    -value.clamp(0, order.total)
  end
end
