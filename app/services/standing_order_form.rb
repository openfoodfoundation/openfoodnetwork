require 'open_food_network/proxy_order_syncer'

class StandingOrderForm
  attr_accessor :standing_order, :params, :fee_calculator, :order_update_issues, :validator, :order_updater

  delegate :json_errors, :valid?, to: :validator
  delegate :order_update_issues, to: :order_updater

  def initialize(standing_order, params = {}, fee_calculator = nil)
    @standing_order = standing_order
    @params = params
    @fee_calculator = fee_calculator
    @validator = StandingOrderValidator.new(standing_order)
    @order_updater = StandingOrderUpdater.new(standing_order)
  end

  def save
    validate_price_estimates
    standing_order.assign_attributes(params)
    return false unless valid?
    standing_order.transaction do
      proxy_order_syncer.sync!
      order_updater.update!
      standing_order.save!
    end
  end

  private

  def proxy_order_syncer
    OpenFoodNetwork::ProxyOrderSyncer.new(standing_order)
  end

  def validate_price_estimates
    item_attributes = params[:standing_line_items_attributes]
    return if item_attributes.blank?
    if fee_calculator
      item_attributes.each do |item_attrs|
        if variant = Spree::Variant.find_by_id(item_attrs[:variant_id])
          item_attrs[:price_estimate] = price_estimate_for(variant)
        else
          item_attrs.delete(:price_estimate)
        end
      end
    else
      item_attributes.each { |item_attrs| item_attrs.delete(:price_estimate) }
    end
  end

  def price_estimate_for(variant)
    fees = fee_calculator.indexed_fees_for(variant)
    (variant.price + fees).to_d
  end
end
