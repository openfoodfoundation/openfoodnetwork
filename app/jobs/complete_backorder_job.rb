# frozen_string_literal: true

# After an order cycle closed, we need to finalise open draft orders placed
# to replenish stock.
class CompleteBackorderJob < ApplicationJob
  def perform(user, order_id)
    # TODO: review our stock levels and adjust quantities if we got surplus.
    # This can happen when orders are cancelled and products restocked.
    service = FdcBackorderer.new(user)
    order = service.find_order(order_id)
    adjust_quantities(order)
    service.complete_order(order)
  end

  # Check if we have enough stock to reduce the backorder.
  #
  # Our local stock can increase when users cancel their orders.
  # But stock levels could also have been adjusted manually. So we review all
  # quantities before finalising the order.
  def adjust_quantities(order)
    # TODO
  end
end
