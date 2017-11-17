class ProxyOrder < ActiveRecord::Base
  belongs_to :order, class_name: 'Spree::Order', dependent: :destroy
  belongs_to :standing_order
  belongs_to :order_cycle

  delegate :number, :completed_at, :total, to: :order, allow_nil: true

  scope :closed, -> { joins(:order_cycle).merge(OrderCycle.closed) }
  scope :not_closed, -> { joins(:order_cycle).merge(OrderCycle.not_closed) }
  scope :not_canceled, where('proxy_orders.canceled_at IS NULL')
  scope :placed_and_open, joins(:order).not_closed.where(spree_orders: { state: 'complete' })

  def state
    return 'canceled' if canceled?
    if !order || order_cycle.orders_open_at > Time.zone.now
      standing_order.paused? ? 'paused' : 'pending'
    else
      return 'cart' if placed_and_open?
      order.state
    end
  end

  def canceled?
    canceled_at.present?
  end

  def cancel
    return false unless order_cycle.orders_close_at.andand > Time.zone.now
    transaction do
      update_column(:canceled_at, Time.zone.now)
      order.send('cancel') if order
      true
    end
  end

  def resume
    return false unless order_cycle.orders_close_at.andand > Time.zone.now
    transaction do
      update_column(:canceled_at, nil)
      order.send('resume') if order
      true
    end
  end

  def initialise_order!
    return order if order.present?
    create_order!(
      customer_id: standing_order.customer_id,
      email: standing_order.customer.email,
      order_cycle_id: order_cycle_id,
      distributor_id: standing_order.shop_id,
      shipping_method_id: standing_order.shipping_method_id
    )
    order.update_attribute(:user, standing_order.customer.user)
    standing_order.standing_line_items.each do |sli|
      order.line_items.build(variant_id: sli.variant_id, quantity: sli.quantity, skip_stock_check: true)
    end
    order.update_attributes(bill_address: standing_order.bill_address.dup, ship_address: standing_order.ship_address.dup)
    order.update_distribution_charge!
    order.payments.create(payment_method_id: standing_order.payment_method_id, amount: order.reload.total)

    save!
    order
  end

  private

  def placed_and_open?
    order.andand.state == 'complete' &&
      order_cycle.orders_close_at > Time.zone.now
  end
end
