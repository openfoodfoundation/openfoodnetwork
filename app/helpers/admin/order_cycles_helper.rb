# frozen_string_literal: true

module Admin
  module OrderCyclesHelper
    def order_cycle_shared_payment_methods(order_cycle)
      order_cycle.attachable_payment_methods.
        where("distributor_id IN (?)", order_cycle.distributors.select(:id)).
        group("spree_payment_methods.id").
        having("COUNT(DISTINCT(distributor_id)) > 1")
    end

    def order_cycle_shared_shipping_methods(order_cycle)
      order_cycle.attachable_shipping_methods.
        where("distributor_id IN (?)", order_cycle.distributors.select(:id)).
        group("spree_shipping_methods.id").
        having("COUNT(DISTINCT(distributor_id)) > 1")
    end
  end
end
