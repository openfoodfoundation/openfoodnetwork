# frozen_string_literal: true

class OrderCycleDistributorPaymentMethod < ApplicationRecord
  self.table_name = "order_cycles_distributor_payment_methods"

  belongs_to :order_cycle
  belongs_to :distributor_payment_method
end
