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
        shipping_rates = calculate_shipping_rates(package)
        shipping_rates.select! { |rate| rate.shipping_method.frontend? } if frontend_only

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

      def calculate_shipping_rates(package)
        shipping_methods(package).map do |shipping_method|
          cost = shipping_method.calculator.compute(package)
          tax_category = shipping_method.tax_category

          if tax_category
            tax_rate = tax_category.tax_rates.detect do |rate|
              rate.zone == package.order.tax_zone
            end
          end

          if cost
            rate = shipping_method.shipping_rates.new(cost: cost)
            rate.tax_rate = tax_rate if tax_rate
          end

          rate
        end.compact
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
