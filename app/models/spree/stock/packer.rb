# frozen_string_literal: true

module Spree
  module Stock
    class Packer
      attr_reader :stock_location, :order, :package_factory

      def initialize(stock_location, order)
        @stock_location = stock_location
        @order = order
        @package_factory = Spree::Config.package_factory
      end

      def packages
        [default_package]
      end

      def default_package
        package = package_factory.new(stock_location, order)
        order.line_items.each do |line_item|
          if Config.track_inventory_levels
            next unless stock_location.stock_item(line_item.variant)

            on_hand, backordered = stock_location.fill_status(line_item.variant, line_item.quantity)
            package.add line_item.variant, on_hand, :on_hand if on_hand.positive?
            package.add line_item.variant, backordered, :backordered if backordered.positive?
          else
            package.add line_item.variant, line_item.quantity, :on_hand
          end
        end
        package
      end
    end
  end
end
