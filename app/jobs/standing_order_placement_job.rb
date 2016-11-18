class StandingOrderPlacementJob
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
    Spree::Order.incomplete.where(order_cycle_id: order_cycle).joins(:standing_order).readonly(false)
  end

  def process(order)
    changes = cap_quantity_and_store_changes(order) unless order.completed?
    until order.completed?
      if order.errors.any?
        Bugsnag.notify(RuntimeError.new("StandingOrderPlacementError"), {
          job: "StandingOrderPlacement",
          error: "Cannot process order due to errors",
          data: {
            errors: order.errors.full_messages
          }
        })
        break
      else
        order.next!
      end
    end
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

  def send_placement_email(order, changes)
    Spree::OrderMailer.standing_order_placement_email(order, changes).deliver
  end
end
