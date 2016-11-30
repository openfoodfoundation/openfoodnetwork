class StandingOrderOrder < ActiveRecord::Base
  belongs_to :order, class_name: 'Spree::Order', dependent: :destroy
  belongs_to :standing_order

  scope :closed, -> { joins(order: :order_cycle).merge(OrderCycle.closed) }
  scope :not_closed, -> { joins(order: :order_cycle).merge(OrderCycle.not_closed) }

  def cancel
    transaction do
      if order.order_cycle.orders_close_at > Time.zone.now
        self.update_column(:cancelled_at, Time.zone.now)
        order.send('cancel') if order.complete?
      end
      self
    end
  end
end
