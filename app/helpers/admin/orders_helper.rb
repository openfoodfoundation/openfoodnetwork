module Admin
  module OrdersHelper
    # Adjustments to display under "Order adjustments".
    #
    # We exclude shipping method adjustments because they are displayed in a
    # separate table together with the order line items.
    def order_adjustments_for_display(order)
      order.all_adjustments.enterprise_fee +
        order.all_adjustments.payment_fee.eligible +
        order.adjustments.admin
    end
  end
end
