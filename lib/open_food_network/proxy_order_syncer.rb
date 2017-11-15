module OpenFoodNetwork
  class ProxyOrderSyncer
    attr_reader :standing_order

    delegate :order_cycles, :proxy_orders, :begins_at, :ends_at, to: :standing_order

    def initialize(standing_orders)
      case standing_orders
      when StandingOrder
        @standing_order = standing_orders
      when ActiveRecord::Relation
        @standing_orders = standing_orders.not_ended.not_canceled
      else
        raise "ProxyOrderSyncer must be initialized with an instance of StandingOrder or ActiveRecord::Relation"
      end
    end

    def sync!
      return sync_all! if @standing_orders
      initialise_proxy_orders!
      remove_obsolete_proxy_orders!
    end

    private

    def sync_all!
      @standing_orders.each do |standing_order|
        @standing_order = standing_order
        initialise_proxy_orders!
        remove_obsolete_proxy_orders!
      end
    end

    def initialise_proxy_orders!
      uninitialised_order_cycle_ids.each do |order_cycle_id|
        proxy_orders << ProxyOrder.new(standing_order: standing_order, order_cycle_id: order_cycle_id)
      end
    end

    def uninitialised_order_cycle_ids
      not_closed_in_range_order_cycles.pluck(:id) - proxy_orders.map(&:order_cycle_id)
    end

    def remove_obsolete_proxy_orders!
      obsolete_proxy_orders.destroy_all
    end

    def obsolete_proxy_orders
      in_range_order_cycle_ids = in_range_order_cycles.pluck(:id)
      return proxy_orders unless in_range_order_cycle_ids.any?
      proxy_orders.where('order_cycle_id NOT IN (?)', in_range_order_cycle_ids)
    end

    def not_closed_in_range_order_cycles
      in_range_order_cycles.merge(OrderCycle.not_closed)
    end

    def in_range_order_cycles
      order_cycles.where('orders_close_at >= ? AND orders_close_at <= ?', begins_at, ends_at || 100.years.from_now)
    end
  end
end
