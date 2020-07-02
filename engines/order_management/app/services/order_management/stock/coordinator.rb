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

      # Build packages as per stock location
      #
      # It needs to check whether each stock location holds at least one stock
      # item for the order. In case none is found it wouldn't make any sense
      # to build a package because it would be empty. Plus we avoid errors down
      # the stack because it would assume the stock location has stock items
      # for the given order
      #
      # Returns an array of Package instances
      def build_packages(packages = [])
        Spree::StockLocation.active.each do |stock_location|
          next unless stock_location.stock_items.
            where(variant_id: order.line_items.pluck(:variant_id)).exists?

          packer = build_packer(stock_location, order)
          packages += packer.packages
        end
        packages
      end

      private

      def prioritize_packages(packages)
        prioritizer = Spree::Stock::Prioritizer.new(order, packages)
        prioritizer.prioritized_packages
      end

      def estimate_packages(packages)
        estimator = Spree::Stock::Estimator.new(order)
        packages.each do |package|
          package.shipping_rates = estimator.shipping_rates(package)
        end
        packages
      end

      def build_packer(stock_location, order)
        Spree::Stock::Packer.new(stock_location, order)
      end
    end
  end
end
