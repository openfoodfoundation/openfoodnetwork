# frozen_string_literal: true

class VoucherAdjustmentsService
  def initialize(order)
    @order = order
  end

  def calculate
    return if @order.nil?

    # Find open Voucher Adjustment
    return if @order.voucher_adjustments.empty?

    # We only support one voucher per order right now, we could just loop on voucher_adjustments
    adjustment = @order.voucher_adjustments.first

    # Calculate value
    amount = adjustment.originator.compute_amount(@order)

    # It is quite possible to have an order with both tax included in and tax excluded from price.
    # We should be able to caculate the relevant amount apply the current calculation.
    #
    # For now we just assume it is either all tax included in price or all tax excluded from price.
    if @order.additional_tax_total.positive?
      handle_tax_excluded_from_price(amount)
    elsif @order.included_tax_total.positive?
      handle_tax_included_in_price(amount)
    else
      adjustment.amount = amount
      adjustment.save
    end
  end

  private

  def handle_tax_excluded_from_price(amount)
    voucher_rate = amount / @order.pre_discount_total

    adjustment = @order.voucher_adjustments.first

    # Adding the voucher tax part
    tax_amount = voucher_rate * @order.additional_tax_total

    adjustment_attributes = {
      originator: adjustment.originator,
      order: @order,
      label: "Tax #{adjustment.label}",
      mandatory: false,
      state: 'open',
      tax_category: nil,
      included_tax: 0
    }

    # Update the amount if tax adjustment already exist, create if not
    tax_adjustment = @order.adjustments.find_or_initialize_by(adjustment_attributes)
    tax_adjustment.amount = tax_amount
    tax_adjustment.save

    # Update the adjustment amount
    adjustment_amount = voucher_rate * (@order.pre_discount_total - @order.additional_tax_total)

    adjustment.update_columns(
      amount: adjustment_amount,
      updated_at: Time.zone.now
    )
  end

  def handle_tax_included_in_price(amount)
    voucher_rate = amount / @order.pre_discount_total
    included_tax = voucher_rate * @order.included_tax_total

    # Update Adjustment
    adjustment = @order.voucher_adjustments.first

    return unless amount != adjustment.amount || included_tax != 0

    adjustment.update_columns(
      amount: amount,
      included_tax: included_tax,
      updated_at: Time.zone.now
    )
  end
end
