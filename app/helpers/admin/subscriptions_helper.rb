# frozen_string_literal: true

module Admin
  module SubscriptionsHelper
    def subscriptions_setup_complete?(shops)
      return false unless shops.any?

      shops = shops.select{ |shop| shipping_and_payment_methods_ok?(shop) && customers_ok?(shop) }
      Schedule.joins(:order_cycles).where(order_cycles: { coordinator_id: shops }).any?
    end

    def shipping_and_payment_methods_ok?(shop)
      shop.present? && shop.shipping_methods.any? && shop.payment_methods.for_subscriptions.any?
    end

    def customers_ok?(shop)
      shop.present? && shop.customers.any?
    end

    def schedules_ok?(shop)
      shop.present? && Schedule.with_coordinator(shop).any?
    end
  end
end
