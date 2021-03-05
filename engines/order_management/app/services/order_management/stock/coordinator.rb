# frozen_string_literal: true

module OrderManagement
  module Stock
    class Coordinator
      attr_reader :order

      def initialize(order)
        @order = order
      end

      def package
        package = build_package
        package = prioritize_package(package)
        estimate_package(package)
      end

      # Build package with default stock location
      # No need to check items are in the stock location,
      #   there is only one stock location so the items will be on that stock location.
      #
      # Returns a single Package for the default stock location
      def build_package
        packer = build_packer(order)
        packer.package
      end

      private

      def prioritize_package(package)
        prioritizer = OrderManagement::Stock::Prioritizer.new(order, package)
        prioritizer.prioritized_package
      end

      def estimate_package(package)
        estimator = OrderManagement::Stock::Estimator.new(order)
        package.shipping_rates = estimator.shipping_rates(package)
        package
      end

      def build_packer(order)
        stock_location = DefaultStockLocation.find_or_create
        OrderManagement::Stock::Packer.new(stock_location, order)
      end
    end
  end
end
