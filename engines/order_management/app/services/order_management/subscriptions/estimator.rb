# frozen_string_literal: true

require 'open_food_network/scope_variant_to_hub'

# Responsible for estimating prices and fees for subscriptions
# Used by Form as part of the create/update process
# The values calculated here are intended to be persisted in the db

module OrderManagement
  module Subscriptions
    class Estimator
      def initialize(subscription)
        @subscription = subscription
      end

      def estimate!
        assign_price_estimates
        assign_fee_estimates
      end

      private

      attr_accessor :subscription

      delegate :subscription_line_items, :shipping_method, :payment_method, :shop, to: :subscription

      def assign_price_estimates
        subscription_line_items.each do |item|
          item.price_estimate =
            price_estimate_for(item.variant, item.price_estimate_was)
        end
      end

      def price_estimate_for(variant, fallback)
        return fallback unless fee_calculator && variant

        scoper.scope(variant)
        fees = fee_calculator.indexed_fees_for(variant)
        (variant.price + fees).to_d
      end

      def fee_calculator
        return @fee_calculator unless @fee_calculator.nil?

        next_oc = subscription.schedule&.current_or_next_order_cycle
        return nil unless shop && next_oc

        @fee_calculator = OpenFoodNetwork::EnterpriseFeeCalculator.new(shop, next_oc)
      end

      def scoper
        OpenFoodNetwork::ScopeVariantToHub.new(shop)
      end

      def assign_fee_estimates
        subscription.shipping_fee_estimate = shipping_fee_estimate
        subscription.payment_fee_estimate = payment_fee_estimate
      end

      def shipping_fee_estimate
        shipping_method.calculator.compute(subscription)
      end

      def payment_fee_estimate
        payment_method.calculator.compute(subscription)
      end
    end
  end
end
