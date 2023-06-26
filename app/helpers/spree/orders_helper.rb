# frozen_string_literal: true

module Spree
  module OrdersHelper
    def cart_is_empty
      order = current_order(false)
      order.nil? || order.line_items.empty?
    end

    def last_completed_order
      spree_current_user.orders.complete.last
    end

    def cart_count
      current_order&.line_items&.count || 0
    end

    def changeable_orders
      # Only returns open order for the current user + shop + oc combo
      return @changeable_orders unless @changeable_orders.nil?
      return @changeable_orders = [] unless spree_current_user &&
                                            current_distributor && current_order_cycle
      return @changeable_orders = [] unless current_distributor.allow_order_changes?

      @changeable_orders = Spree::Order.complete.where(
        state: 'complete',
        user_id: spree_current_user.id,
        distributor_id: current_distributor.id,
        order_cycle_id: current_order_cycle.id
      )
    end

    def changeable_orders_link_path
      changeable_orders.one? ? main_app.order_path(changeable_orders.first) : spree.account_path
    end

    def shop_changeable_orders_alert_html
      return "" unless changeable_orders.any?

      t(:shop_changeable_orders_alert_html,
        count: changeable_orders.count,
        path: changeable_orders_link_path,
        order: changeable_orders.first.number,
        shop: current_distributor.name,
        oc_close: l(current_order_cycle.orders_close_at, format: "%A, %b %d, %Y @ %H:%M"))
    end
  end
end
