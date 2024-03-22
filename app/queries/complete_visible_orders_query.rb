# frozen_string_literal: true

class CompleteVisibleOrdersQuery
  def initialize(order_permissions)
    @order_permissions = order_permissions
  end

  def call
    order_permissions.visible_orders.complete
  end

  private

  attr_reader :order_permissions
end
