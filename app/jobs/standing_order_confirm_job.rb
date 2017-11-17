require 'open_food_network/standing_order_payment_updater'

class StandingOrderConfirmJob
  def perform
    ids = proxy_orders.pluck(:id)
    proxy_orders.update_all(confirmed_at: Time.zone.now)
    ProxyOrder.where(id: ids).each do |proxy_order|
      @order = proxy_order.order
      process!
    end
  end

  private

  def proxy_orders
    ProxyOrder.not_canceled.where('confirmed_at IS NULL AND placed_at IS NOT NULL')
      .joins(:order_cycle).merge(recently_closed_order_cycles)
      .joins(:standing_order).merge(StandingOrder.not_canceled.not_paused)
      .joins(:order).merge(Spree::Order.complete)
  end

  def recently_closed_order_cycles
    OrderCycle.closed.where('order_cycles.orders_close_at BETWEEN (?) AND (?) OR order_cycles.updated_at BETWEEN (?) AND (?)', 1.hour.ago, Time.zone.now, 1.hour.ago, Time.zone.now)
  end

  def process!
    update_payment! if @order.payment_required?
    return send_failed_payment_email if @order.errors.present?
    @order.process_payments! if @order.payment_required?
    return send_failed_payment_email if @order.errors.present?
    send_confirm_email
  end

  def update_payment!
    result = payment_updater.new(@order).update!
    case result
    when :no_card
      @order.errors.add(:base, I18n.t("activerecord.errors.models.standing_order.no_card"))
    end
  end

  def send_confirm_email
    StandingOrderMailer.confirmation_email(@order).deliver
  end

  def send_failed_payment_email
    StandingOrderMailer.failed_payment_email(@order).deliver
  end

  def payment_updater
    OpenFoodNetwork::StandingOrderPaymentUpdater
  end
end
