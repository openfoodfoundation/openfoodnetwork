class StandingOrderConfirmJob
  def perform
    ids = proxy_orders.pluck(:id)
    proxy_orders.update_all(confirmed_at: Time.now)
    ProxyOrder.where(id: ids).each do |proxy_order|
      process(proxy_order.order)
    end
  end

  private

  def proxy_orders
    ProxyOrder.not_canceled.where('confirmed_at IS NULL AND placed_at IS NOT NULL')
    .joins(:order_cycle).merge(recently_closed_order_cycles)
    .joins(:standing_order).merge(StandingOrder.not_canceled.not_paused)
    .joins(:order).merge(Spree::Order.complete)
  end

  def process(order)
    send_confirm_email(order)
  end

  def send_confirm_email(order)
    Spree::OrderMailer.standing_order_email(order.id, 'confirmation', {}).deliver
  end

  def recently_closed_order_cycles
    OrderCycle.closed.where('order_cycles.orders_close_at BETWEEN (?) AND (?) OR order_cycles.updated_at BETWEEN (?) AND (?)', 1.hour.ago, Time.now, 1.hour.ago, Time.now)
  end
end
