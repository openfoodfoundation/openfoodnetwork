# frozen_string_literal: true

module OrderManagement
  module Stock
    class Coordinator
      attr_reader :order

      def initialize(order)
        @order = order
      end

      def packages
        packages = build_packages
        packages = prioritize_packages(packages)
        estimate_packages(packages)
      end

      # Build package with default stock location
      # No need to check items are in the stock location,
      #   there is only one stock location so the items will be on that stock location.
      #
      # Returns an array with a single Package for the default stock location
      def build_packages
        packer = build_packer(order)
        [packer.package]
      end

      private

      def prioritize_packages(packages)
        prioritizer = OrderManagement::Stock::Prioritizer.new(order, packages)
        prioritizer.prioritized_packages
      end

      def estimate_packages(packages)
        estimator = OrderManagement::Stock::Estimator.new(order)
        packages.each do |package|
          package.shipping_rates = estimator.shipping_rates(package)
        end
        packages
      end

      def build_packer(order)
        stock_location = DefaultStockLocation.find_or_create
        OrderManagement::Stock::Packer.new(stock_location, order)
      end
    end
  end
end
