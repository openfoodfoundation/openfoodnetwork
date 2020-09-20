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
        shipping_methods = select_shipping_methods(package)
        return [] unless shipping_methods

        shipping_methods.each do |shipping_method|
          cost = calculate_cost(shipping_method, package)
          shipping_rates << shipping_method.shipping_rates.new(cost: cost) unless cost.nil?
        end

        shipping_rates.sort_by! { |r| r.cost || 0 }

        unless shipping_rates.empty?
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

        shipping_rates
      end

      private

      def select_shipping_methods(package)
        package
          .shipping_methods
          .reject do |ship_method|
            method_currency = ship_method.calculator.preferences&.dig(:currency)

            !ship_method.calculator.available?(package) ||
              !ship_method.include?(order.ship_address) ||
              !(method_currency.nil? || method_currency == currency)
          end
      end

      def calculate_cost(shipping_method, package)
        shipping_method.calculator.compute(package)
      end
    end
  end
end
