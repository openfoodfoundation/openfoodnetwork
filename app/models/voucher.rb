# frozen_string_literal: false

class Voucher < ApplicationRecord
  self.belongs_to_required_by_default = false

  acts_as_paranoid

  belongs_to :enterprise, optional: false

  # We want to keep the association with the adjustment when a voucher is "destroyed" as we use
  # the soft delete functionality to activate/deactivate vouchers
  has_many :adjustments,
           as: :originator,
           class_name: 'Spree::Adjustment',
           dependent: nil

  validates :code, presence: true

  TYPES = ["Vouchers::FlatRate", "Vouchers::PercentageRate"].freeze

  def code=(value)
    super(value.to_s.strip)
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
      order:,
      label:,
      mandatory: false,
      state: "open",
      tax_category: nil
    }

    order.adjustments.create(adjustment_attributes)
  end

  # The following method must be overriden in a concrete voucher.
  def display_value
    raise NotImplementedError, 'please use concrete voucher'
  end

  def compute_amount(_order)
    raise NotImplementedError, 'please use concrete voucher'
  end

  def rate(_order)
    raise NotImplementedError, 'please use concrete voucher'
  end
end
