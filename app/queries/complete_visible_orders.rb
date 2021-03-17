# frozen_string_literal: true

class CompleteVisibleOrders
  def initialize(order_permissions)
    @order_permissions = order_permissions
  end

  def query
    order_permissions.visible_orders.complete
  end

  private

  attr_reader :order_permissions
end
