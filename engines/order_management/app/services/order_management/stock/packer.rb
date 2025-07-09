# frozen_string_literal: true

module OrderManagement
  module Stock
    class Packer
      attr_reader :order

      def initialize(order)
        @order = order
      end

      def package
        package = OrderManagement::Stock::Package.new(order)
        order.line_items.each do |line_item|
          variant = line_item.variant
          next unless variant.stock_item

          OpenFoodNetwork::ScopeVariantToHub.new(order.distributor).scope(variant)

          on_hand, backordered = variant.fill_status(line_item.quantity)
          package.add variant, on_hand, :on_hand if on_hand.positive?
          package.add variant, backordered, :backordered if backordered.positive?
        end
        package
      end
    end
  end
end
