# frozen_string_literal: true

class AddToCartComponent < ViewComponent::Base
  def initialize(variant:, quantity:, low_stock_display: )
    @variant = variant
    @quantity = quantity
    @low_stock_display = low_stock_display
  end

  attr_reader :variant, :quantity, :low_stock_display

  private

  def on_hand
    # Javascript will parse "Infinity" as the Infinity global property
    variant.on_demand ? "Infinity" : variant.on_hand
  end
end
