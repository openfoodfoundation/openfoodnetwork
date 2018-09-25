# Used to prevent payments on subscriptions from being processed in the normal way.
# Payments are skipped until after the order cycle has closed.
module OrderSubscriptionsExtensions
  # Override Spree method.
  def payment_required?
    super && !skip_payment_for_subscription?
  end

  private

  def skip_payment_for_subscription?
    subscription.present? && order_cycle.orders_close_at.andand > Time.zone.now
  end
end
