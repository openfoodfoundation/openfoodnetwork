class StandingOrderPlacementJob
  attr_accessor :order_cycle

  def initialize(order_cycle)
    @order_cycle = order_cycle
  end

  def perform
    orders
  end

  def orders
    Spree::Order.incomplete.where(order_cycle_id: order_cycle).joins(:standing_order)
  end
end
