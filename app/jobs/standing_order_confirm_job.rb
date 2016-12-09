class StandingOrderConfirmJob
  attr_accessor :order_cycle

  def initialize(order_cycle)
    @order_cycle = order_cycle
  end

  def perform
    orders.each do |order|
      process(order)
    end
  end

  private

  def orders
    Spree::Order.complete.where(order_cycle_id: order_cycle)
    .merge(StandingOrderOrder.not_canceled).joins(:standing_order_order).readonly(false)
  end

  def process(order)
    send_confirm_email(order)
  end

  def send_confirm_email(order)
    Spree::OrderMailer.standing_order_email(order.id, 'confirmation', {}).deliver
  end
end
