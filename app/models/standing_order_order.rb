class StandingOrderOrder < ActiveRecord::Base
  belongs_to :order, class_name: 'Spree::Order', dependent: :destroy
  belongs_to :standing_order

  delegate :number, :order_cycle_id, :completed_at, :total, to: :order

  scope :closed, -> { joins(order: :order_cycle).merge(OrderCycle.closed) }
  scope :not_closed, -> { joins(order: :order_cycle).merge(OrderCycle.not_closed) }

  def state
    return 'canceled' if cancelled?
    order.state
  end

  def cancelled?
    cancelled_at.present?
  end

  def cancel
    return false unless order.order_cycle.andand.orders_close_at.andand > Time.zone.now
    transaction do
      self.update_column(:cancelled_at, Time.zone.now)
      order.send('cancel')
      true
    end
  end

  def resume
    return false unless order.order_cycle.orders_close_at > Time.zone.now
    transaction do
      self.update_column(:cancelled_at, nil)
      order.send('resume')
      true
    end
  end
end
