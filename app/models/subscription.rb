# frozen_string_literal: true

class Subscription < ApplicationRecord
  include SetUnusedAddressFields

  ALLOWED_PAYMENT_METHOD_TYPES = ["Spree::PaymentMethod::Check",
                                  "Spree::Gateway::StripeSCA"].freeze

  self.belongs_to_required_by_default = false

  searchable_attributes :shop_id, :canceled_at, :paused_at
  searchable_associations :shop
  searchable_scopes :active, :not_ended, :not_paused, :not_canceled

  belongs_to :shop, class_name: 'Enterprise'
  belongs_to :customer
  belongs_to :schedule
  belongs_to :shipping_method, class_name: 'Spree::ShippingMethod'
  belongs_to :payment_method, class_name: 'Spree::PaymentMethod'
  belongs_to :bill_address, class_name: "Spree::Address"
  belongs_to :ship_address, class_name: "Spree::Address"
  has_many :subscription_line_items, inverse_of: :subscription, dependent: :destroy
  has_many :order_cycles, through: :schedule
  has_many :proxy_orders, dependent: :destroy
  has_many :orders, through: :proxy_orders

  alias_attribute :billing_address, :bill_address
  alias_attribute :shipping_address, :ship_address

  accepts_nested_attributes_for :subscription_line_items, allow_destroy: true
  accepts_nested_attributes_for :bill_address, :ship_address

  scope :not_ended, -> {
                      where('subscriptions.ends_at > (?) OR subscriptions.ends_at IS NULL',
                            Time.zone.now)
                    }
  scope :not_canceled, -> { where('subscriptions.canceled_at IS NULL') }
  scope :not_paused, -> { where('subscriptions.paused_at IS NULL') }
  scope :active, -> {
                   not_canceled.not_ended.not_paused.where('subscriptions.begins_at <= (?)',
                                                           Time.zone.now)
                 }

  def closed_proxy_orders
    proxy_orders.closed
  end

  def not_closed_proxy_orders
    proxy_orders.not_closed
  end

  def cancel(keep_ids = [])
    transaction do
      update_column(:canceled_at, Time.zone.now)
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
    # NOTE: the order is important here
    %w(canceled paused pending ended).each do |state|
      return state if __send__("#{state}?")
    end
    "active"
  end

  # Used to calculators to estimate fees
  def line_items
    subscription_line_items
  end

  private

  def pending?
    return true unless begins_at

    begins_at > Time.zone.now
  end

  def ended?
    return false unless ends_at

    ends_at < Time.zone.now
  end
end
