module Spree
  module OrdersHelper
    def cart_is_empty
      order = current_order(false)
      order.nil? || order.line_items.empty?
    end

    def alternative_available_distributors(order)
      DistributionChangeValidator.new(order).available_distributors(Enterprise.all) - [order.distributor]
    end

    def last_completed_order
      spree_current_user.orders.complete.last
    end

    def cart_count
      current_order.andand.line_items.andand.count || 0
    end

    def changeable_orders
      return [] unless spree_current_user && current_distributor && current_order_cycle
      Spree::Order.complete.where(
        user_id: spree_current_user.id,
        distributor_id: current_distributor.id,
        order_cycle_id: current_order_cycle.id)
    end
  end
end
