# frozen_string_literal: true

class OrderCycleShippingMethod < ApplicationRecord
  belongs_to :order_cycle
  belongs_to :shipping_method, class_name: "Spree::ShippingMethod"

  validate :shipping_method_belongs_to_order_cycle_distributor
  validates :shipping_method, uniqueness: { scope: :order_cycle_id }

  private

  def shipping_method_belongs_to_order_cycle_distributor
    return if order_cycle.nil? ||
              shipping_method.nil? ||
              shipping_method.distributors.where(id: order_cycle.distributor_ids).exists?

    errors.add(:shipping_method, :must_belong_to_order_cycle_distributor)
  end
end
