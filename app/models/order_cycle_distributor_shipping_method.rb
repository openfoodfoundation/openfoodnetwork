# frozen_string_literal: true

class OrderCycleDistributorShippingMethod < ApplicationRecord
  self.table_name = "order_cycles_distributor_shipping_methods"

  belongs_to :order_cycle
  belongs_to :distributor_shipping_method
end
