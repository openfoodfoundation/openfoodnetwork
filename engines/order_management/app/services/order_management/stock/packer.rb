# frozen_string_literal: true

module OrderManagement
  module Stock
    class Packer
      attr_reader :stock_location, :order

      def initialize(stock_location, order)
        @stock_location = stock_location
        @order = order
      end

      def package
        package = OrderManagement::Stock::Package.new(stock_location, order)
        order.line_items.each do |line_item|
          next unless stock_location.stock_item(line_item.variant)

          variant = line_item.variant
          OpenFoodNetwork::ScopeVariantToHub.new(order.distributor).scope(variant)

          on_hand, backordered = stock_location.fill_status(variant, line_item.quantity)
          package.add variant, on_hand, :on_hand if on_hand.positive?
          package.add variant, backordered, :backordered if backordered.positive?
        end
        package
      end
    end
  end
end
