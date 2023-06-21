# frozen_string_literal: false

module OrderManagement
  module Subscriptions
    class ProxyOrderSyncer
      attr_reader :subscription

      delegate :order_cycles, :proxy_orders, :begins_at, :ends_at, to: :subscription

      def initialize(subscriptions)
        case subscriptions
        when Subscription
          @subscription = subscriptions
        when ActiveRecord::Relation
          @subscriptions = subscriptions.not_ended.not_canceled
        else
          raise "ProxyOrderSyncer must be initialized with " \
                "an instance of Subscription or ActiveRecord::Relation"
        end
      end

      def sync!
        return sync_subscriptions! if @subscriptions

        return initialise_proxy_orders! unless @subscription.id

        sync_subscription!
      end

      private

      def sync_subscriptions!
        @subscriptions.each do |subscription|
          @subscription = subscription
          sync_subscription!
        end
      end

      def initialise_proxy_orders!
        uninitialised_order_cycle_ids.each do |order_cycle_id|
          Rails.logger.info "Initializing Proxy Order " \
                            "of subscription #{@subscription.id} in order cycle #{order_cycle_id}"
          proxy_orders << ProxyOrder.new(subscription: subscription, order_cycle_id: order_cycle_id)
        end
      end

      def sync_subscription!
        Rails.logger.info "Syncing Proxy Orders of subscription #{@subscription.id}"
        create_proxy_orders!
        remove_orphaned_proxy_orders!
      end

      def create_proxy_orders!
        return unless not_closed_in_range_order_cycles.any?

        query = "INSERT INTO proxy_orders (subscription_id, order_cycle_id, updated_at, created_at)"
        query << " VALUES #{insert_values}"
        query << " ON CONFLICT DO NOTHING"

        ActiveRecord::Base.connection.exec_query(query)
      end

      def uninitialised_order_cycle_ids
        not_closed_in_range_order_cycles.pluck(:id) - proxy_orders.map(&:order_cycle_id)
      end

      def remove_orphaned_proxy_orders!
        orphaned_proxy_orders.where(nil).delete_all
      end

      # Remove Proxy Orders that have not been placed yet
      #   and are in Order Cycles that are out of range
      def orphaned_proxy_orders
        orphaned = proxy_orders.where(placed_at: nil)
        order_cycle_ids = in_range_order_cycles.pluck(:id)
        return orphaned unless order_cycle_ids.any?

        orphaned.where('order_cycle_id NOT IN (?)', order_cycle_ids)
      end

      def insert_values
        now = Time.now.utc.iso8601
        not_closed_in_range_order_cycles
          .map{ |oc| "(#{subscription.id},#{oc.id},'#{now}','#{now}')" }
          .join(",")
      end

      def not_closed_in_range_order_cycles
        in_range_order_cycles.merge(OrderCycle.not_closed)
      end

      def in_range_order_cycles
        order_cycles.where("orders_close_at >= ? AND orders_close_at <= ?",
                           begins_at,
                           ends_at || 100.years.from_now)
      end
    end
  end
end
