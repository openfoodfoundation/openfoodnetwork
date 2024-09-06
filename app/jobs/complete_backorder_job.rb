# frozen_string_literal: true

# After an order cycle closed, we need to finalise open draft orders placed
# to replenish stock.
class CompleteBackorderJob < ApplicationJob
  def perform(user, order_id)
    # TODO: review our stock levels and adjust quantities if we got surplus.
    # This can happen when orders are cancelled and products restocked.
    FdcBackorderer.new(user).complete_order(order_id)
  end
end
