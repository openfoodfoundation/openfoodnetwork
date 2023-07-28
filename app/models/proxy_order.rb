# frozen_string_literal: true

# Each Subscription has many ProxyOrders, one for each OrderCycle to which the Subscription applies
# Proxy pattern allows for deferral of initialization until absolutely required
# This reduces the need to keep Orders in sync with their parent Subscriptions

class ProxyOrder < ApplicationRecord
  self.belongs_to_required_by_default = false

  belongs_to :order, class_name: 'Spree::Order'
  belongs_to :subscription
  belongs_to :order_cycle

  delegate :number, :completed_at, :total, to: :order, allow_nil: true

  scope :active, -> { joins(:order_cycle).merge(OrderCycle.active) }
  scope :closed, -> { joins(:order_cycle).merge(OrderCycle.closed) }
  scope :not_closed, -> { joins(:order_cycle).merge(OrderCycle.not_closed) }
  scope :canceled, -> { where('proxy_orders.canceled_at IS NOT NULL') }
  scope :not_canceled, -> { where('proxy_orders.canceled_at IS NULL') }
  scope :placed_and_open, -> {
                            joins(:order).not_closed
                              .where(spree_orders: { state: ['complete', 'resumed'] })
                          }

  def state
    # NOTE: the order is important here
    %w(canceled paused pending cart).each do |state|
      return state if __send__("#{state}?")
    end
    order.state
  end

  def canceled?
    canceled_at.present?
  end

  def cancel
    return false unless order_cycle.orders_close_at&.>(Time.zone.now)

    transaction do
      update_column(:canceled_at, Time.zone.now)
      order&.cancel
      true
    end
  end

  def resume
    return false unless order_cycle.orders_close_at&.>(Time.zone.now)

    transaction do
      update_column(:canceled_at, nil)
      order&.resume
      true
    end
  end

  def initialise_order!
    return order if order.present?

    factory = OrderFactory.new(order_attrs, skip_stock_check: true)
    self.order = factory.create
    save!
    order
  end

  private

  def paused?
    pending? && subscription.paused?
  end

  def pending?
    !order || order_cycle.orders_open_at > Time.zone.now
  end

  def cart?
    order&.state == 'complete' &&
      order_cycle.orders_close_at > Time.zone.now
  end

  def order_attrs
    attrs = subscription.attributes.slice("customer_id", "payment_method_id", "shipping_method_id")
    attrs[:distributor_id] = subscription.shop_id
    attrs[:order_cycle_id] = order_cycle_id
    attrs[:bill_address_attributes] = subscription.bill_address.attributes.except("id")
    attrs[:ship_address_attributes] = subscription.ship_address.attributes.except("id")
    attrs[:line_items] = subscription.subscription_line_items.map do |sli|
      { variant_id: sli.variant_id, quantity: sli.quantity }
    end
    attrs
  end
end
