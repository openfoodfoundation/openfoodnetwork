require 'open_food_network/subscription_payment_updater'
require 'open_food_network/subscription_summarizer'

class SubscriptionConfirmJob
  def perform
    ids = proxy_orders.pluck(:id)
    proxy_orders.update_all(confirmed_at: Time.zone.now)
    ProxyOrder.where(id: ids).each do |proxy_order|
      @order = proxy_order.order
      process!
    end

    send_confirmation_summary_emails
  end

  private

  delegate :record_order, :record_success, :record_issue, to: :summarizer
  delegate :record_and_log_error, :send_confirmation_summary_emails, to: :summarizer

  def summarizer
    @summarizer ||= OpenFoodNetwork::SubscriptionSummarizer.new
  end

  def proxy_orders
    ProxyOrder.not_canceled.where('confirmed_at IS NULL AND placed_at IS NOT NULL')
      .joins(:order_cycle).merge(recently_closed_order_cycles)
      .joins(:order).merge(Spree::Order.complete)
  end

  def recently_closed_order_cycles
    OrderCycle.closed.where('order_cycles.orders_close_at BETWEEN (?) AND (?) OR order_cycles.updated_at BETWEEN (?) AND (?)', 1.hour.ago, Time.zone.now, 1.hour.ago, Time.zone.now)
  end

  def process!
    record_order(@order)
    update_payment! if @order.payment_required?
    return send_failed_payment_email if @order.errors.present?
    @order.process_payments! if @order.payment_required?
    return send_failed_payment_email if @order.errors.present?
    send_confirm_email
  end

  def update_payment!
    OpenFoodNetwork::SubscriptionPaymentUpdater.new(@order).update!
  end

  def send_confirm_email
    @order.update!
    record_success(@order)
    SubscriptionMailer.confirmation_email(@order).deliver
  end

  def send_failed_payment_email
    @order.update!
    record_and_log_error(:failed_payment, @order)
    SubscriptionMailer.failed_payment_email(@order).deliver
  end
end
