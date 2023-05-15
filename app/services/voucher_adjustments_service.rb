# frozen_string_literal: true

class VoucherAdjustmentsService
  def self.calculate(order)
    return if order.nil?

    # Find open Voucher Adjustment
    return if order.voucher_adjustments.empty?

    # We only support one voucher per order right now, we could just loop on voucher_adjustments
    adjustment = order.voucher_adjustments.first

    # Recalculate value
    amount = adjustment.originator.compute_amount(order)

    # It is quite possible to have an order with both tax included in and tax excluded from price.
    # We should be able to caculate the relevant amount apply the current calculation.
    #
    # For now we just assume it is either all tax included in price or all tax excluded from price.
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

    # Adding the voucher tax part
    tax_amount = voucher_rate * order.additional_tax_total

    adjustment = order.voucher_adjustments.first
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
    adjustment = order.voucher_adjustments.first

    return unless amount != adjustment.amount || included_tax != 0

    adjustment.update_columns(
      amount: amount,
      included_tax: included_tax,
      updated_at: Time.zone.now
    )
  end

  private_class_method :handle_tax_included_in_price, :handle_tax_excluded_from_price
end
