# frozen_string_literal: true

# Quantity widget to add a variant to the cart and change its quantity,
# used in the product grid when the turbo_cart feature is enabled.
# Changes are saved by the add-to-cart Stimulus controller, which submits
# to PATCH /cart/variants/:variant_id and renders the Turbo Stream
# response with the updated cart sidebar.
class AddToCartComponent < ViewComponent::Base
  LOW_STOCK_THRESHOLD = 3

  def initialize(variant:, order:, distributor: nil)
    @variant = variant
    @order = order
    @distributor = distributor
    super()
  end

  private

  attr_reader :variant, :order, :distributor

  def quantity
    @quantity ||= order&.find_line_item_by_variant(variant)&.quantity || 0
  end

  def in_cart?
    quantity.positive?
  end

  def out_of_stock?
    !variant.on_demand && variant.on_hand <= 0
  end

  def show_low_stock?
    distributor&.preferred_product_low_stock_display &&
      !variant.on_demand && variant.on_hand <= LOW_STOCK_THRESHOLD
  end

  def form_options
    {
      id: "add-to-cart-#{variant.id}",
      class: "add-to-cart",
      data: {
        controller: "add-to-cart",
        turbo: true,
        action: "submit->add-to-cart#submit",
        'add-to-cart-variant-id-value': variant.id,
        'add-to-cart-quantity-value': quantity,
        'add-to-cart-on-hand-value': variant.on_hand,
        'add-to-cart-on-demand-value': variant.on_demand.to_s,
      },
    }
  end
end
