class StandingOrderPlacementJob
  attr_accessor :proxy_orders

  def initialize(proxy_orders)
    @proxy_orders = proxy_orders
  end

  def perform
    proxy_orders.each do |proxy_order|
      proxy_order.initialise_order!
      process(proxy_order.order)
    end
  end

  private

  def process(order)
    return if order.completed?
    changes = cap_quantity_and_store_changes(order) unless order.completed?
    move_to_completion(order)
    send_placement_email(order, changes)
  end

  def cap_quantity_and_store_changes(order)
    changes = {}
    insufficient_stock_lines = order.insufficient_stock_lines
    insufficient_stock_lines.each_with_object(changes) do |line_item, changes|
      changes[line_item.id] = line_item.quantity
      line_item.cap_quantity_at_stock!
    end
    unavailable_stock_lines = unavailable_stock_lines_for(order)
    unavailable_stock_lines.each_with_object(changes) do |line_item, changes|
      changes[line_item.id] = changes[line_item.id] || line_item.quantity
      line_item.update_attributes(quantity: 0)
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

  def unavailable_stock_lines_for(order)
    order.line_items.where('variant_id NOT IN (?)', available_variants_for(order))
  end

  def available_variants_for(order)
    DistributionChangeValidator.new(order).variants_available_for_distribution(order.distributor, order.order_cycle)
  end

  def send_placement_email(order, changes)
    return unless order.completed?
    Spree::OrderMailer.standing_order_email(order.id, 'placement', changes).deliver
  end
end
