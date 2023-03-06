# frozen_string_literal: true

module OrderManagement
  module Stock
    class Estimator
      attr_reader :order, :currency

      def initialize(order)
        @order = order
        @currency = order.currency
      end

      def shipping_rates(package, frontend_only = true)
        shipping_rates = []
        shipping_methods = shipping_methods(package)
        return [] unless shipping_methods

        shipping_methods.each do |shipping_method|
          cost = calculate_cost(shipping_method, package)
          shipping_rates << shipping_method.shipping_rates.new(cost: cost) unless cost.nil?
        end

        shipping_rates.sort_by! { |r| r.cost || 0 }

        unless shipping_rates.empty? || order.manual_shipping_selection
          select_first_shipping_method(shipping_rates, frontend_only)
        end

        shipping_rates
      end

      def calculate_cost(shipping_method, package)
        shipping_method.calculator.compute(package)
      end

      private

      # Sets the first available shipping method to "selected".
      # Note: seems like a hangover from Spree, we can probably just remove this at some point.
      def select_first_shipping_method(shipping_rates, frontend_only)
        if frontend_only
          shipping_rates.each do |rate|
            if rate.shipping_method.frontend?
              rate.selected = true
              break
            end
          end
        else
          shipping_rates.first.selected = true
        end
      end

      def shipping_methods(package)
        shipping_methods = package.shipping_methods
        shipping_methods.delete_if { |ship_method| !ship_method.calculator.available?(package) }
        shipping_methods.delete_if { |ship_method| !ship_method.include?(order.ship_address) }
        shipping_methods.delete_if { |ship_method|
          !(ship_method.calculator.preferences[:currency].nil? ||
            ship_method.calculator.preferences[:currency] == currency)
        }
        shipping_methods
      end
    end
  end
end
