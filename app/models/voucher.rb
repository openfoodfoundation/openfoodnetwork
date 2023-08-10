# frozen_string_literal: false

class Voucher < ApplicationRecord
  acts_as_paranoid

  belongs_to :enterprise, optional: false

  has_many :adjustments,
           as: :originator,
           class_name: 'Spree::Adjustment',
           dependent: :nullify

  validates :code, presence: true, uniqueness: { scope: :enterprise_id }
  validates :amount, presence: true, numericality: { greater_than: 0 }

  def code=(value)
    super(value.to_s.strip)
  end

  def display_value
    Spree::Money.new(amount)
  end

  # Ideally we would use `include CalculatedAdjustments` to be consistent with other adjustments,
  # but vouchers have complicated calculation so we can't easily use Spree::Calculator. We keep
  # the same method to stay as consistent as possible.
  #
  # Creates a new voucher adjustment for the given order with an amount of 0
  # The amount will be calculated via VoucherAdjustmentsService#update
  def create_adjustment(label, order)
    adjustment_attributes = {
      amount: 0,
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
    -amount.clamp(0, order.pre_discount_total)
  end
end
