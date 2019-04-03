module Admin
  module OrdersHelper
    # Adjustments to display under "Order adjustments".
    #
    # We exclude shipping method adjustments because they are displayed in a
    # separate table together with the order line items.
    #
    # We also exclude tax rate adjustment with zero value.
    def order_adjustments_for_display(order)
      order.adjustments.eligible.select do |adjustment|
        type = adjustment.originator_type

        is_shipping_method_adjustment = (type == 'Spree::ShippingMethod')
        is_zero_tax_rate_adjustment = (type == 'Spree::TaxRate' && adjustment.amount.zero?)

        !is_shipping_method_adjustment && !is_zero_tax_rate_adjustment
      end
    end
  end
end
