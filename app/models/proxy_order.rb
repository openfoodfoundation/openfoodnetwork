class ProxyOrder < ActiveRecord::Base
  belongs_to :order, class_name: 'Spree::Order', dependent: :destroy
  belongs_to :standing_order
  belongs_to :order_cycle

  delegate :number, :completed_at, :total, to: :order, allow_nil: true

  scope :closed, -> { joins(order: :order_cycle).merge(OrderCycle.closed) }
  scope :not_closed, -> { joins(order: :order_cycle).merge(OrderCycle.not_closed) }
  scope :not_canceled, where('proxy_orders.canceled_at IS NULL')

  def state
    return 'canceled' if canceled?
    order.state
  end

  def canceled?
    canceled_at.present?
  end

  def cancel
    return false unless order_cycle.orders_close_at.andand > Time.zone.now
    transaction do
      self.update_column(:canceled_at, Time.zone.now)
      order.send('cancel')
      true
    end
  end

  def resume
    return false unless order_cycle.orders_close_at.andand > Time.zone.now
    transaction do
      self.update_column(:canceled_at, nil)
      order.send('resume')
      true
    end
  end

  def initialise_order!
    create_order!({
      customer_id: standing_order.customer_id,
      email: standing_order.customer.email,
      order_cycle_id: order_cycle_id,
      distributor_id: standing_order.shop_id,
      shipping_method_id: standing_order.shipping_method_id,
    })
    standing_order.standing_line_items.each do |sli|
      order.line_items.build(variant_id: sli.variant_id, quantity: sli.quantity, skip_stock_check: true)
    end
    order.update_attributes(bill_address: standing_order.bill_address.dup, ship_address: standing_order.ship_address.dup)
    order.update_distribution_charge!
    order.payments.create(payment_method_id: standing_order.payment_method_id, amount: order.reload.total)

    save!
    order
  end
end
