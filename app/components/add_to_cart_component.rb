# frozen_string_literal: true

class AddToCartComponent < ViewComponent::Base
  def initialize(variant:, cart_item:, low_stock_display:, css_class: "")
    @variant = variant
    @cart_item = cart_item
    @low_stock_display = low_stock_display
    @css_class = css_class
  end

  attr_reader :variant, :cart_item, :low_stock_display

  private

  def quantity
    cart_item.quantity
  end

  def max_quantity
    cart_item.max_quantity
  end

  def group_buy?
    # group_buy is a nullable boolean column: coerce nil to false so the group-buy-value data
    # attribute is always a valid "true"/"false" for Stimulus's Boolean value parsing.
    !!variant.product.group_buy
  end

  def on_hand
    # Javascript will parse "Infinity" as the Infinity global property
    variant.on_demand ? "Infinity" : variant.on_hand
  end

  def component_css
    "add-to-cart-component #{@css_class}"
  end
end
