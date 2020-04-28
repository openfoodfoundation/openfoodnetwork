# frozen_string_literal: true

require 'order_management/subscriptions/proxy_order_syncer'

module OrderManagement
  module Subscriptions
    class Form
      attr_accessor :subscription, :subscription_params, :order_update_issues,
                    :validator, :order_syncer, :estimator

      delegate :json_errors, :valid?, to: :validator
      delegate :order_update_issues, to: :order_syncer

      def initialize(subscription, subscription_params = {})
        @subscription = subscription
        @subscription_params = subscription_params
        @estimator = OrderManagement::Subscriptions::Estimator.new(subscription)
        @validator = OrderManagement::Subscriptions::Validator.new(subscription)
        @order_syncer = OrderSyncer.new(subscription)
      end

      def save
        subscription.assign_attributes(subscription_params)
        return false unless valid?

        subscription.transaction do
          estimator.estimate!
          proxy_order_syncer.sync!
          order_syncer.sync!
          subscription.save!
        end
      end

      private

      def proxy_order_syncer
        OrderManagement::Subscriptions::ProxyOrderSyncer.new(subscription)
      end
    end
  end
end
