# frozen_string_literal: true

module OrderManagement
  module Stock
    class Prioritizer
      attr_reader :packages, :order

      def initialize(order, package, adjuster_class = OrderManagement::Stock::Adjuster)
        @order = order
        @package = package
        @adjuster_class = adjuster_class
      end

      def prioritized_package
        adjust_package
        return if package.empty?

        package
      end

      private

      def adjust_package
        order.line_items.each do |line_item|
          adjuster = @adjuster_class.new(line_item.variant, line_item.quantity, :on_hand)

          visit_package(adjuster)

          adjuster.status = :backordered
          visit_package(adjuster)
        end
      end

      def visit_package(adjuster)
        item = package.find_item(adjuster.variant, adjuster.status)
        adjuster.adjust(item) if item
      end
    end
  end
end
