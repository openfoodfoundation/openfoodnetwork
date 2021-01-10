# frozen_string_literal: true

require 'order_management/subscriptions/proxy_order_syncer'

module OrderManagement
  module Subscriptions
    class Form
      attr_accessor :subscription, :subscription_params, :order_update_issues,
                    :validator, :order_syncer, :estimator

      delegate :json_errors, :valid?, to: :validator
      delegate :order_update_issues, to: :order_syncer

      def initialize(subscription, subscription_params = {}, options = {})
        @subscription = subscription
        @subscription_params = subscription_params
        @options = options
        @estimator = OrderManagement::Subscriptions::Estimator.new(subscription)
        @validator = OrderManagement::Subscriptions::Validator.new(subscription)
        @order_syncer = OrderSyncer.new(subscription)
      end

      def save
        subscription.assign_attributes(subscription_params.to_h)
        return false unless valid?

        subscription.transaction do
          subscription.paused_at = nil if @options[:unpause]
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
