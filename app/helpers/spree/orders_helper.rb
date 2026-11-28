# frozen_string_literal: true

module Spree
  module OrdersHelper
    def last_completed_order
      spree_current_user.orders.complete.last
    end

    def changeable_orders
      # Only returns open order for the current user + shop + oc combo
      @changeable_orders ||= if spree_current_user &&
                                current_order_cycle && current_distributor&.allows_order_changes?

                               Spree::Order.complete.where(
                                 state: 'complete',
                                 user_id: spree_current_user.id,
                                 distributor_id: current_distributor.id,
                                 order_cycle_id: current_order_cycle.id
                               )
                             else
                               []
                             end
    end

    # The customer's placed orders in this shop and order cycle that the cart can be added to, most
    # recent first. Subscription orders are left out: their subscription keeps them up to date.
    def addable_orders
      @addable_orders ||= changeable_orders
        .select { |order| order.additions_allowed? && order.proxy_order.nil? }
        .sort_by(&:completed_at).reverse
    end

    def changeable_orders_link_path
      changeable_orders.one? ? main_app.order_path(changeable_orders.first) : account_path
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

    def format_unit_price(unit_price)
      "#{Spree::Money.new(unit_price[:amount]).to_html}&nbsp;/&nbsp;#{unit_price[:unit]}".html_safe # rubocop:disable Rails/OutputSafety
    end
  end
end
