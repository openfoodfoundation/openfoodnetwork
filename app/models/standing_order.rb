class StandingOrder < ActiveRecord::Base
  ALLOWED_PAYMENT_METHOD_TYPES = ["Spree::PaymentMethod::Check", "Spree::Gateway::StripeConnect"]

  belongs_to :shop, class_name: 'Enterprise'
  belongs_to :customer
  belongs_to :schedule
  belongs_to :shipping_method, class_name: 'Spree::ShippingMethod'
  belongs_to :payment_method, class_name: 'Spree::PaymentMethod'
  belongs_to :bill_address, foreign_key: :bill_address_id, class_name: Spree::Address
  belongs_to :ship_address, foreign_key: :ship_address_id, class_name: Spree::Address
  belongs_to :credit_card, foreign_key: :credit_card_id, class_name: 'Spree::CreditCard'
  has_many :standing_line_items, inverse_of: :standing_order
  has_many :order_cycles, through: :schedule
  has_many :proxy_orders
  has_many :orders, through: :proxy_orders

  alias_attribute :billing_address, :bill_address
  alias_attribute :shipping_address, :ship_address

  accepts_nested_attributes_for :standing_line_items, allow_destroy: true
  accepts_nested_attributes_for :bill_address, :ship_address

  scope :not_ended, -> { where('standing_orders.ends_at > (?) OR standing_orders.ends_at IS NULL', Time.zone.now) }
  scope :not_canceled, where('standing_orders.canceled_at IS NULL')
  scope :not_paused, where('standing_orders.paused_at IS NULL')
  scope :active, -> { not_canceled.not_ended.not_paused.where('standing_orders.begins_at <= (?)', Time.zone.now) }

  def closed_proxy_orders
    proxy_orders.closed
  end

  def not_closed_proxy_orders
    proxy_orders.not_closed
  end

  def cancel(keep_ids = [])
    transaction do
      self.update_column(:canceled_at, Time.zone.now)
      proxy_orders.reject{ |o| keep_ids.include? o.id }.each(&:cancel)
      true
    end
  end

  def canceled?
    canceled_at.present?
  end

  def paused?
    paused_at.present?
  end

  def state
    return 'canceled' if canceled?
    return 'paused' if paused?
    return nil unless begins_at
    if begins_at > Time.zone.now
      'pending'
    else
      return 'ended' if ends_at.andand < Time.zone.now
      'active'
    end
  end
end
