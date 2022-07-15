# frozen_string_literal: true

module Admin
  module OrderCyclesHelper
    def order_cycle_distributors_payment_methods(order_cycle)
      Spree::PaymentMethod.
        joins(:distributors).
        includes(:distributors).
        available(:both).
        where("distributor_id IN (?)", order_cycle.distributors.select(:id))
    end

    def order_cycle_distributors_shipping_methods(order_cycle)
      Spree::ShippingMethod.
        joins(:distributors).
        includes(:distributors).
        where("distributor_id IN (?)", order_cycle.distributors.select(:id))
    end
  end
end
