# frozen_string_literal: true

module OrderManagement
  module Subscriptions
    class Summary
      attr_reader :shop_id, :issues, :subscription_issues

      def initialize(shop_id)
        @shop_id = shop_id
        @order_ids = []
        @success_ids = []
        @issues = {}
        @subscription_issues = []
      end

      def record_order(order)
        @order_ids << order.id
      end

      def record_success(order)
        @success_ids << order.id
      end

      def record_issue(type, order, message)
        issues[type] ||= {}
        issues[type][order.id] = message
      end

      def record_subscription_issue(subscription)
        @subscription_issues << subscription.id
      end

      def order_count
        @order_ids.count
      end

      def success_count
        @success_ids.count
      end

      def issue_count
        (@order_ids - @success_ids).count + @subscription_issues.count
      end

      def orders_affected_by(type)
        case type
        when :other then Spree::Order.where(id: unrecorded_ids)
        else Spree::Order.where(id: issues[type].keys)
        end
      end

      def unrecorded_ids
        recorded_ids = issues.values.map(&:keys).flatten
        @order_ids - @success_ids - recorded_ids
      end
    end
  end
end
