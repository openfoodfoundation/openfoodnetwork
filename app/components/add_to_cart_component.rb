# frozen_string_literal: true

class AddToCartComponent < ViewComponent::Base
  # `cart_params` names the shop and order cycle to add in, for pages which can't count
  # on the cart being pointed at them already. See CartController#adopt_shop.
  def initialize(variant:, quantity:, low_stock_display:, css_class: "", cart_params: {})
    @variant = variant
    @quantity = quantity
    @low_stock_display = low_stock_display
    @css_class = css_class
    @cart_params = cart_params
  end

  attr_reader :variant, :quantity, :low_stock_display

  private

  attr_reader :cart_params

  def cart_url
    helpers.main_app.variant_cart_path(variant.id, cart_params)
  end

  def on_hand
    # Javascript will parse "Infinity" as the Infinity global property
    variant.on_demand ? "Infinity" : variant.on_hand
  end

  def component_css
    "add-to-cart-component #{@css_class}"
  end
end
