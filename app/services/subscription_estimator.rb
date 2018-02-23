class SubscriptionEstimator
  def initialize(subscription, fee_calculator)
    @subscription = subscription
    @fee_calculator = fee_calculator
  end

  def estimate!
    assign_price_estimates
  end

  private

  attr_accessor :subscription, :fee_calculator

  delegate :subscription_line_items, to: :subscription

  def assign_price_estimates
    subscription_line_items.each do |item|
      item.price_estimate = price_estimate_for(item.variant)
    end
  end

  def price_estimate_for(variant)
    return 0.0 unless fee_calculator && variant
    fees = fee_calculator.indexed_fees_for(variant)
    (variant.price + fees).to_d
  end
end
