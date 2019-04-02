module Admin
  module OrdersHelper
    def order_adjustments(order)
      order.adjustments.eligible
    end
  end
end
