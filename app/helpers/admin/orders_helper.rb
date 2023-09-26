# frozen_string_literal: true

module Admin
  module OrdersHelper
    # Adjustments to display under "Order adjustments".
    #
    # We exclude shipping method adjustments because they are displayed in a
    # separate table together with the order line items.
    def order_adjustments_for_display(order)
      adjustments_for_display = order.adjustments + order.all_adjustments.payment_fee.eligible

      if VoucherAdjustmentsService.new(order).voucher_included_tax.negative?
        adjustment = order.voucher_adjustments.first
        adjustments_for_display << Spree::Adjustment.new(
          label: I18n.t("admin.orders.edit.voucher_tax_included_in_price", label: adjustment.label),
          amount: adjustment.included_tax
        )
      end

      adjustments_for_display
    end
  end
end
