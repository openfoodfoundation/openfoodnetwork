class OrderCycleOpenCloseJob
  def perform
    recently_opened_order_cycles.each do |order_cycle|
      proxy_orders = placeable_proxy_orders_for(order_cycle).all
      if proxy_orders.any?
        placeable_proxy_orders_for(order_cycle).update_all(placed_at: Time.now)
        Delayed::Job.enqueue(StandingOrderPlacementJob.new(proxy_orders))
      end
    end

    recently_closed_order_cycles.each do |order_cycle|
      proxy_orders = confirmable_proxy_orders_for(order_cycle).all
      if proxy_orders.any?
        confirmable_proxy_orders_for(order_cycle).update_all(confirmed_at: Time.now)
        Delayed::Job.enqueue(StandingOrderConfirmJob.new(proxy_orders))
      end
    end
  end

  private

  def recently_opened_order_cycles
    OrderCycle.active.where('(orders_open_at BETWEEN (?) AND (?) OR updated_at BETWEEN (?) AND (?))', 10.minutes.ago, Time.now, 10.minutes.ago, Time.now)
  end

  def recently_closed_order_cycles
    OrderCycle.closed.where('(orders_close_at BETWEEN (?) AND (?) OR updated_at BETWEEN (?) AND (?))', 10.minutes.ago, Time.now, 10.minutes.ago, Time.now)
  end

  def placeable_proxy_orders_for(order_cycle)
    # Load proxy orders for standing orders whose begins at date may between now and the order cycle close date
    # Does not load proxy orders for standing orders who ends_at date is before order_cycle close
    ProxyOrder.not_canceled.where(order_cycle_id: order_cycle, placed_at: nil)
    .where('begins_at < ? AND (ends_at IS NULL OR ends_at > ?)', order_cycle.orders_close_at, order_cycle.orders_close_at)
    .joins(:standing_order).merge(StandingOrder.not_canceled.not_paused)
    .readonly(false)
  end

  def confirmable_proxy_orders_for(order_cycle)
    ProxyOrder.not_canceled.where(order_cycle_id: order_cycle, confirmed_at: nil).where('placed_at IS NOT NULL')
    .where('begins_at < ? AND (ends_at IS NULL OR ends_at > ?)', order_cycle.orders_close_at, order_cycle.orders_close_at)
    .joins(:standing_order).merge(StandingOrder.not_canceled.not_paused)
    .joins(:order).merge(Spree::Order.complete)
    .readonly(false)
  end
end
