# frozen_string_literal: true

module Api
  module Admin
    class SubscriptionLineItemSerializer < ActiveModel::Serializer
      attributes :id, :variant_id, :quantity, :description, :price_estimate,
                 :in_open_and_upcoming_order_cycles

      def description
        "#{object.variant.product.name} - #{object.variant.full_name}"
      end

      def price_estimate
        object.price_estimate&.to_f || "?"
      end

      def in_open_and_upcoming_order_cycles
        OrderManagement::Subscriptions::VariantsList
          .in_open_and_upcoming_order_cycles?(
            option_or_assigned_shop,
            option_or_assigned_schedule,
            object.variant
          )
      end

      private

      def option_or_assigned_shop
        @options[:shop] || object.subscription&.shop
      end

      def option_or_assigned_schedule
        @options[:schedule] || object.subscription&.schedule
      end
    end
  end
end
