# frozen_string_literal: true

# Inheriting from SimplerDelegator and calling super(variant) makes sure any method not defined
# in the presenter are delagated to the variant model
class VariantPresenter < SimpleDelegator
  def initialize(variant:, distributor: nil, order_cycle: nil, enterprise_fee_calculator: nil)
    @variant = variant
    super(variant)

    @distributor = distributor
    @order_cycle = order_cycle
    @enterprise_fee_calculator = enterprise_fee_calculator
  end

  attr_reader :variant, :distributor, :order_cycle

  def unit_price_price
    price_with_fees / (unit_price.denominator || 1)
  end

  def display_unit_price
    Spree::Money.new(unit_price_price).to_s
  end

  def price_with_fees
    return variant.price + fee_breakdown.sum(&:amount) if @enterprise_fee_calculator

    # TODO should leave outside the variant model
    variant.price_with_fees(distributor, order_cycle)
  end

  # The fees on the price, each on its own. Needs an enterprise fee calculator.
  def fee_breakdown
    @fee_breakdown ||= @enterprise_fee_calculator.indexed_fee_breakdown_for(variant)
  end

  def display_price_with_fees
    Spree::Money.new(price_with_fees).to_s
  end

  def unit_price
    @unit_price ||= UnitPrice.new(variant)
  end
end
