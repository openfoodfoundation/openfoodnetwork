class StandingOrderConfirmJob
  attr_accessor :proxy_orders

  def initialize(proxy_orders)
    @proxy_orders = proxy_orders
  end

  def perform
    proxy_orders.each do |proxy_order|
      process(proxy_order.order)
    end
  end

  private

  def process(order)
    send_confirm_email(order)
  end

  def send_confirm_email(order)
    Spree::OrderMailer.standing_order_email(order.id, 'confirmation', {}).deliver
  end
end
