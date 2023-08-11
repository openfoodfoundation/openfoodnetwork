# frozen_string_literal: true

class VoucherAdjustmentsService
  def initialize(order)
    @order = order
  end

  def update
    return if @order.nil?

    # Find open Voucher Adjustment
    return if @order.voucher_adjustments.empty?

    # We only support one voucher per order right now, we could just loop on voucher_adjustments
    adjustment = @order.voucher_adjustments.first

    # Calculate value
    voucher = adjustment.originator
    amount = voucher.compute_amount(@order)

    # It is quite possible to have an order with both tax included in and tax excluded from price.
    # We should be able to caculate the relevant amount apply the current calculation.
    #
    # For now we just assume it is either all tax included in price or all tax excluded from price.
    if @order.additional_tax_total.positive?
      handle_tax_excluded_from_price(voucher)
    elsif @order.included_tax_total.positive?
      handle_tax_included_in_price(amount, voucher)
    else
      adjustment.amount = amount
      adjustment.save
    end
  end

  def handle_tax_excluded_from_price(voucher)
    voucher_rate = voucher.rate(@order)
    adjustment = @order.voucher_adjustments.first

    # Adding the voucher tax part
    tax_amount = voucher_rate * @order.additional_tax_total

    update_tax_adjustment_for(adjustment, tax_amount)

    # Update the adjustment amount
    adjustment_amount = voucher_rate * (@order.pre_discount_total - @order.additional_tax_total)

    adjustment.update_columns(
      amount: adjustment_amount,
      updated_at: Time.zone.now
    )
  end

  def update_tax_adjustment_for(adjustment, tax_amount)
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
  end

  def handle_tax_included_in_price(amount, voucher)
    included_tax = voucher.rate(@order) * @order.included_tax_total

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
