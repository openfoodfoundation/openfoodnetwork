# frozen_string_literal: true

class DistributorShippingMethod < ApplicationRecord
  self.table_name = "distributors_shipping_methods"

  belongs_to :shipping_method, class_name: "Spree::ShippingMethod", touch: true
  belongs_to :distributor, class_name: "Enterprise", touch: true

  has_many :order_cycle_distributor_shipping_methods, dependent: :destroy
  has_many :order_cycles, through: :order_cycle_distributor_shipping_methods
end
