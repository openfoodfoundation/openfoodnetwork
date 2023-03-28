# frozen_string_literal: false

class Voucher < ApplicationRecord
  acts_as_paranoid

  include CalculatedAdjustments

  belongs_to :enterprise

  has_many :adjustments, as: :originator, class_name: 'Spree::Adjustment'

  validates :code, presence: true, uniqueness: { scope: :enterprise_id }

  before_validation :add_calculator

  def self.adjust!(order)
    return if order.nil?

    # Find open Voucher Adjustment
    return if order.vouchers.empty?

    # We only support one voucher per order right now, we could just loop on vouchers
    adjustment = order.vouchers.first

    # Recalculate value
    amount = adjustment.originator.compute_amount(order)

    if order.additional_tax_total.positive?
      handle_tax_excluded_from_price(order, amount)
    else
      handle_tax_included_in_price(order, amount)
    end

    # Move to closed state
    adjustment.close
  end

  def self.handle_tax_excluded_from_price(order, amount)
    voucher_rate = amount / order.total

    # TODO: might need to use VoucherTax has originator (sub class of Voucher)
    # Adding the voucher tax part
    tax_amount = voucher_rate * order.additional_tax_total

    adjustment = order.vouchers.first
    adjustment_attributes = {
      amount: tax_amount,
      originator: adjustment.originator,
      order: order,
      label: "Tax #{adjustment.label}",
      mandatory: false,
      state: 'closed',
      tax_category: nil,
      included_tax: 0
    }
    order.adjustments.create(adjustment_attributes)

    # Update the adjustment amount
    amount = voucher_rate * (order.total - order.additional_tax_total)

    adjustment.update_columns(
      amount: amount,
      updated_at: Time.zone.now
    )
  end

  def self.handle_tax_included_in_price(order, amount)
    voucher_rate = amount / order.total
    included_tax = voucher_rate * order.included_tax_total

    # Update Adjustment
    adjustment = order.vouchers.first

    return unless amount != adjustment.amount || included_tax != 0

    adjustment.update_columns(
      amount: amount,
      included_tax: included_tax,
      updated_at: Time.zone.now
    )
  end

  def value
    10
  end

  def display_value
    Spree::Money.new(value)
  end

  # override the one from CalculatedAdjustments
  # Create an "open" adjustment which will be updated later once tax and other fees have
  # been applied to the order
  def create_adjustment(label, order, mandatory = false, _state = "open", tax_category = nil)
    amount = compute_amount(order)

    return if amount.zero? && !mandatory

    adjustment_attributes = {
      amount: amount,
      originator: self,
      order: order,
      label: label,
      mandatory: mandatory,
      state: "open",
      tax_category: tax_category
    }

    order.adjustments.create(adjustment_attributes)
  end

  # override the one from CalculatedAdjustments so we limit adjustment to the maximum amount
  # needed to cover the order, ie if the voucher covers more than the order.total we only need
  # to create an adjustment covering the order.total
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
