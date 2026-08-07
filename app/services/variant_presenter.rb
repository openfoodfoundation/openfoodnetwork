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
    if @enterprise_fee_calculator
      return variant.price + @enterprise_fee_calculator.indexed_fees_for(variant)
    end

    # TODO should leave outside the variant model
    variant.price_with_fees(distributor, order_cycle)
  end

  def unit_price
    @unit_price ||= UnitPrice.new(variant)
  end
end
