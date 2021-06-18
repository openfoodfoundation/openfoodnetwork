# frozen_string_literal: true

module Admin
  module OrdersHelper
    # Adjustments to display under "Order adjustments".
    #
    # We exclude shipping method adjustments because they are displayed in a
    # separate table together with the order line items.
    def order_adjustments_for_display(order)
      order.adjustments + order.all_adjustments.payment_fee.eligible
    end
  end
end
