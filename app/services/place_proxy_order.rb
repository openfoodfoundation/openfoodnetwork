# frozen_string_literal: true

class PlaceProxyOrder
  def initialize(proxy_order, summarizer, logger, stock_changes_loader)
    @proxy_order = proxy_order
    @subscription = proxy_order.subscription
    @summarizer = summarizer
    @logger = logger
    @stock_changes_loader = stock_changes_loader
    @order = nil
  end

  def call
    return unless place_order

    summarizer.record_order(order)
    return summarizer.record_issue(:complete, order) if order.completed?

    load_changes
    return handle_empty_order if empty_order?

    order.process_payments! if order.payment_required?
    move_to_completion
    send_placement_email
  rescue StandardError => e
    summarizer.record_and_log_error(:processing, order, e.message)
    Bugsnag.notify(e) do |payload|
      payload.add_metadata :order, :order, order
    end
  end

  private

  attr_reader :proxy_order, :subscription, :summarizer, :logger, :stock_changes_loader, :changes
  attr_accessor :order

  def place_order
    proxy_order.with_lock do
      return if proxy_order.placed_at.present?

      initialise_order
    end
  end

  def initialise_order
    logger.info("Placing Order for Proxy Order #{proxy_order.id}")

    self.order = proxy_order.initialise_order!

    if order.nil?
      summarizer.record_subscription_issue(subscription)
      return false
    end

    mark_as_processed

    true
  rescue StandardError => e
    Bugsnag.notify(e) do |payload|
      payload.add_metadata(:proxy_order, { subscription:, proxy_order: })
    end
    false
  end

  def mark_as_processed
    proxy_order.update_column(:placed_at, Time.zone.now)
  end

  def load_changes
    @changes = stock_changes_loader.call(order)
  end

  def empty_order?
    order.line_items.where('quantity > 0').empty?
  end

  def handle_empty_order
    order.reload.all_adjustments.destroy_all
    order.update_order!
    send_empty_email
  end

  def send_empty_email
    summarizer.record_issue(:empty, order)
    SubscriptionMailer.empty_email(order, changes).deliver_now
  end

  def move_to_completion
    Orders::WorkflowService.new(order).complete!
  end

  def send_placement_email
    summarizer.record_issue(:changes, order) if changes.present?
    summarizer.record_success(order) if changes.blank?

    SubscriptionMailer.placement_email(order, changes).deliver_now
  end
end
