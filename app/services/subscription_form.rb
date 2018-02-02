require 'open_food_network/proxy_order_syncer'

class SubscriptionForm
  attr_accessor :subscription, :params, :fee_calculator, :order_update_issues, :validator, :order_syncer

  delegate :json_errors, :valid?, to: :validator
  delegate :order_update_issues, to: :order_syncer

  def initialize(subscription, params = {}, fee_calculator = nil)
    @subscription = subscription
    @params = params
    @fee_calculator = fee_calculator
    @validator = SubscriptionValidator.new(subscription)
    @order_syncer = OrderSyncer.new(subscription)
  end

  def save
    validate_price_estimates
    subscription.assign_attributes(params)
    return false unless valid?
    subscription.transaction do
      proxy_order_syncer.sync!
      order_syncer.sync!
      subscription.save!
    end
  end

  private

  def proxy_order_syncer
    OpenFoodNetwork::ProxyOrderSyncer.new(subscription)
  end

  def validate_price_estimates
    return unless params[:standing_line_items_attributes]
    return clear_price_estimates unless fee_calculator
    calculate_prices_from_variant_ids
  end

  def clear_price_estimates
    params[:standing_line_items_attributes].each do |item_attrs|
      item_attrs.delete(:price_estimate)
    end
  end

  def calculate_prices_from_variant_ids
    params[:standing_line_items_attributes].each do |item_attrs|
      variant = Spree::Variant.find_by_id(item_attrs[:variant_id])
      next item_attrs.delete(:price_estimate) unless variant
      item_attrs[:price_estimate] = price_estimate_for(variant)
    end
  end

  def price_estimate_for(variant)
    fees = fee_calculator.indexed_fees_for(variant)
    (variant.price + fees).to_d
  end
end
