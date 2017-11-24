require 'open_food_network/standing_order_summarizer'

class StandingOrderPlacementJob
  attr_accessor :summarizer

  delegate :record_order, :record_success, :record_issue, to: :summarizer
  delegate :record_failure, :send_placement_summary_emails, to: :summarizer

  def initialize
    @summarizer = OpenFoodNetwork::StandingOrderSummarizer.new
  end

  def perform
    ids = proxy_orders.pluck(:id)
    proxy_orders.update_all(placed_at: Time.zone.now)
    ProxyOrder.where(id: ids).each do |proxy_order|
      proxy_order.initialise_order!
      process(proxy_order.order)
    end

    send_placement_summary_emails
  end

  private

  def proxy_orders
    # Loads proxy orders for open order cycles that have not been placed yet
    ProxyOrder.not_canceled.where(placed_at: nil)
      .joins(:order_cycle).merge(OrderCycle.active)
      .joins(:standing_order).merge(StandingOrder.not_canceled.not_paused)
  end

  def process(order)
    record_order(order)
    return record_issue(:complete, order) if order.completed?

    changes = cap_quantity_and_store_changes(order)
    if order.line_items.where('quantity > 0').empty?
      return send_empty_email(order, changes)
    end

    move_to_completion(order)
    send_placement_email(order, changes)
  rescue StateMachine::InvalidTransition
    record_failure(order)
  end

  def cap_quantity_and_store_changes(order)
    changes = {}
    order.insufficient_stock_lines.each do |line_item|
      changes[line_item.id] = line_item.quantity
      line_item.cap_quantity_at_stock!
    end
    unavailable_stock_lines_for(order).each do |line_item|
      changes[line_item.id] = changes[line_item.id] || line_item.quantity
      line_item.update_attributes(quantity: 0)
    end
    changes
  end

  def move_to_completion(order)
    until order.completed? do order.next! end
  end

  def unavailable_stock_lines_for(order)
    order.line_items.where('variant_id NOT IN (?)', available_variants_for(order))
  end

  def available_variants_for(order)
    DistributionChangeValidator.new(order).variants_available_for_distribution(order.distributor, order.order_cycle)
  end

  def send_placement_email(order, changes)
    record_issue(:changes, order) if changes.present?
    record_success(order) if changes.blank?
    StandingOrderMailer.placement_email(order, changes).deliver
  end

  def send_empty_email(order, changes)
    record_issue(:empty, order)
    StandingOrderMailer.empty_email(order, changes).deliver
  end
end
