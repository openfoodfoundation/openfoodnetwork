# frozen_string_literal: true

class OrderCycleShippingMethod < ApplicationRecord
  belongs_to :order_cycle
  belongs_to :shipping_method, class_name: "Spree::ShippingMethod"

  validate :shipping_method_belongs_to_order_cycle_distributor
  validate :shipping_method_available_at_checkout
  validate :order_cycle_not_simple
  validates_uniqueness_of :shipping_method, scope: :order_cycle_id

  before_destroy :check_shipping_method_not_selected_on_any_orders

  private

  def shipping_method_not_selected_on_any_orders?
    !Spree::Order.joins(shipments: :shipping_rates).where(
      "order_cycle_id = ? AND spree_shipping_rates.shipping_method_id = ?",
      order_cycle_id, shipping_method_id
    ).exists?
  end

  def check_shipping_method_not_selected_on_any_orders
    return if order_cycle.nil? ||
              shipping_method.nil? ||
              shipping_method_not_selected_on_any_orders?

    errors.add(:base, :shipping_method_already_used_in_order_cycle)
    throw :abort
  end

  def order_cycle_not_simple
    return if order_cycle.nil? || !order_cycle.simple?

    errors.add(:order_cycle, :must_not_be_simple)
  end

  def shipping_method_available_at_checkout
    return if shipping_method.nil? || shipping_method.frontend?

    errors.add(:shipping_method, :must_be_available_at_checkout)
  end

  def shipping_method_belongs_to_order_cycle_distributor
    return if order_cycle.nil? ||
              shipping_method.nil? ||
              shipping_method.distributors.where(id: order_cycle.distributor_ids).exists?

    errors.add(:shipping_method, :must_belong_to_order_cycle_distributor)
  end
end
