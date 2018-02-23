require 'open_food_network/proxy_order_syncer'

class SubscriptionForm
  attr_accessor :subscription, :params, :order_update_issues, :validator, :order_syncer, :estimator

  delegate :json_errors, :valid?, to: :validator
  delegate :order_update_issues, to: :order_syncer

  def initialize(subscription, params = {}, fee_calculator = nil)
    @subscription = subscription
    @params = params
    @estimator = SubscriptionEstimator.new(subscription, fee_calculator)
    @validator = SubscriptionValidator.new(subscription)
    @order_syncer = OrderSyncer.new(subscription)
  end

  def save
    subscription.assign_attributes(params)
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
    OpenFoodNetwork::ProxyOrderSyncer.new(subscription)
  end
end
