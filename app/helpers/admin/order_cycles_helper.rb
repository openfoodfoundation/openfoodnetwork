# frozen_string_literal: true

module Admin
  module OrderCyclesHelper
    def order_cycle_shared_payment_methods(order_cycle)
      order_cycle.attachable_payment_methods.select do |payment_method|
        (payment_method.distributor_ids & order_cycle.distributor_ids).many?
      end
    end

    def order_cycle_shared_shipping_methods(order_cycle)
      order_cycle.attachable_shipping_methods.select do |shipping_method|
        (shipping_method.distributor_ids & order_cycle.distributor_ids).many?
      end
    end
  end
end
