class StandingOrderPlacementJob
  attr_accessor :order_cycle

  def initialize(order_cycle)
    @order_cycle = order_cycle
  end

  def perform
    proxy_orders.each do |proxy_order|
      proxy_order.initialise_order!
      process(proxy_order.order)
    end
  end

  private

  def proxy_orders
    # Load proxy orders for standing orders whose begins at date may between now and the order cycle close date
    # Does not load proxy orders for standing orders who ends_at date is before order_cycle close
    ProxyOrder.not_canceled.where(order_cycle_id: order_cycle)
    .where('begins_at < ? AND (ends_at IS NULL OR ends_at > ?)', order_cycle.orders_close_at, order_cycle.orders_close_at)
    .merge(StandingOrder.not_canceled.not_paused).joins(:standing_order).readonly(false)
  end

  def process(order)
    return if order.completed?
    changes = cap_quantity_and_store_changes(order) unless order.completed?
    move_to_completion(order)
    send_placement_email(order, changes)
  end

  def cap_quantity_and_store_changes(order)
    insufficient_stock_lines = order.insufficient_stock_lines
    return {} unless insufficient_stock_lines.present?
    insufficient_stock_lines.each_with_object({}) do |line_item, changes|
      changes[line_item.id] = line_item.quantity
      line_item.cap_quantity_at_stock!
    end
  end

  def move_to_completion(order)
    until order.completed?
      unless order.next!
        Bugsnag.notify(RuntimeError.new("StandingOrderPlacementError"), {
          job: "StandingOrderPlacement",
          error: "Cannot process order due to errors",
          data: {
            order_number: order.number,
            errors: order.errors.full_messages
          }
        })
        break
      end
    end
  end

  def send_placement_email(order, changes)
    return unless order.completed?
    Spree::OrderMailer.standing_order_email(order.id, 'placement', changes).deliver
  end
end
