# frozen_string_literal: true

class RemoveTransientData
  RETENTION_PERIOD = 3.months.ago.to_date

  # This model lets us operate on the sessions DB table using ActiveRecord's
  # methods within the scope of this service. This relies on the AR's
  # convention where a Session model maps to a sessions table.
  class Session < ApplicationRecord
  end

  def call
    Rails.logger.info("#{self.class.name}: processing")

    Spree::StateChange.where("created_at < ?", RETENTION_PERIOD).delete_all
    Spree::LogEntry.where("created_at < ?", RETENTION_PERIOD).delete_all
    Session.where("updated_at < ?", RETENTION_PERIOD).delete_all

    clear_old_cart_data!
  end

  private

  def clear_old_cart_data!
    old_carts = Spree::Order.
      where("spree_orders.state = 'cart' AND spree_orders.updated_at < ?", RETENTION_PERIOD).
      merge(orders_without_payments)

    old_cart_line_items = Spree::LineItem.where(order_id: old_carts)
    old_cart_adjustments = Spree::Adjustment.where(order_id: old_carts)

    old_cart_adjustments.delete_all
    old_cart_line_items.delete_all
    old_carts.delete_all
  end

  def orders_without_payments
    # Carts with failed payments are ignored, as they contain potentially useful data
    Spree::Order.
      joins("LEFT OUTER JOIN spree_payments ON spree_orders.id = spree_payments.order_id").
      where("spree_payments.id IS NULL")
  end
end
