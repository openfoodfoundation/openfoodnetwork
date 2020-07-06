# frozen_string_literal: true

module OrderManagement
  module Stock
    class Prioritizer
      attr_reader :packages, :order

      def initialize(order, packages, adjuster_class = OrderManagement::Stock::Adjuster)
        @order = order
        @packages = packages
        @adjuster_class = adjuster_class
      end

      def prioritized_packages
        adjust_packages
        prune_packages
        packages
      end

      private

      def adjust_packages
        order.line_items.each do |line_item|
          adjuster = @adjuster_class.new(line_item.variant, line_item.quantity, :on_hand)

          visit_packages(adjuster)

          adjuster.status = :backordered
          visit_packages(adjuster)
        end
      end

      def visit_packages(adjuster)
        packages.each do |package|
          item = package.find_item adjuster.variant, adjuster.status
          adjuster.adjust(item) if item
        end
      end

      def prune_packages
        packages.reject!(&:empty?)
      end
    end
  end
end
