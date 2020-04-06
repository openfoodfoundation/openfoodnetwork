# frozen_string_literal: true

module OrderManagement
  module Subscriptions
    class Count
      def initialize(order_cycles)
        @order_cycles = order_cycles
      end

      def for(order_cycle_id)
        active[order_cycle_id] || 0
      end

      private

      attr_accessor :order_cycles

      def active
        return @active unless @active.nil?
        return @active = [] if order_cycles.blank?

        @active ||= ProxyOrder.
          not_canceled.
          group(:order_cycle_id).
          where(order_cycle_id: order_cycles).
          count
      end
    end
  end
end
