require 'open_food_network/standing_order_updater'

class StandingOrder < ActiveRecord::Base
  include OpenFoodNetwork::StandingOrderUpdater

  belongs_to :shop, class_name: 'Enterprise'
  belongs_to :customer
  belongs_to :schedule
  belongs_to :shipping_method, class_name: 'Spree::ShippingMethod'
  belongs_to :payment_method, class_name: 'Spree::PaymentMethod'
  belongs_to :bill_address, foreign_key: :bill_address_id, class_name: Spree::Address
  belongs_to :ship_address, foreign_key: :ship_address_id, class_name: Spree::Address
  has_many :standing_line_items, inverse_of: :standing_order
  has_many :order_cycles, through: :schedule
  has_many :standing_order_orders
  has_many :orders, through: :standing_order_orders

  alias_attribute :billing_address, :bill_address
  alias_attribute :shipping_address, :ship_address

  accepts_nested_attributes_for :standing_line_items, :bill_address, :ship_address

  validates_presence_of :shop, :customer, :schedule, :payment_method, :shipping_method
  validates_presence_of :billing_address, :shipping_address, :begins_at
  validate :ends_at_after_begins_at
  validate :standing_line_items_available
  validate :check_associations

  after_save :update_orders!

  def ends_at_after_begins_at
    if begins_at.present? && ends_at.present? && ends_at <= begins_at
      errors.add(:ends_at, "must be after begins at")
    end
  end

  def check_associations
    errors[:customer] << "does not belong to #{shop.name}" if customer && customer.enterprise != shop
    errors[:schedule] << "is not coordinated by #{shop.name}" if schedule && schedule.coordinators.exclude?(shop)
    errors[:payment_method] << "is not available to #{shop.name}" if payment_method && payment_method.distributors.exclude?(shop)
    errors[:shipping_method] << "is not available to #{shop.name}" if shipping_method && shipping_method.distributors.exclude?(shop)
  end

  def standing_line_items_available
    standing_line_items.each do |sli|
      unless sli.available_from?(shop_id, schedule_id)
        name = "#{sli.variant.product.name} - #{sli.variant.full_name}"
        errors[:base] << "#{name} is not available from the selected schedule"
      end
    end
  end
end
