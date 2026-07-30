# frozen_string_literal: true

# Quantity widget to add a variant to the cart and change its quantity,
# used in the product grid when the turbo_cart feature is enabled.
# Changes are saved by the add-to-cart Stimulus controller, which submits
# to PATCH /cart/variants/:variant_id and renders the Turbo Stream
# response with the updated cart sidebar.
class AddToCartComponent < ViewComponent::Base
  LOW_STOCK_THRESHOLD = 3

  def initialize(variant:, order:, distributor: nil, order_cycle: nil)
    @variant = variant
    @order = order
    @distributor = distributor
    @order_cycle = order_cycle
    super()
  end

  private

  attr_reader :variant, :order, :distributor, :order_cycle

  def line_item
    @line_item ||= order&.find_line_item_by_variant(variant)
  end

  def quantity
    line_item&.quantity || 0
  end

  def max_quantity
    line_item&.max_quantity || 0
  end

  def group_buy?
    !!variant.product.group_buy
  end

  def bulk_modal_id
    "bulk-buy-modal-#{variant.id}"
  end

  def full_name
    if variant.product.name == variant.name_to_display
      variant.product.name
    else
      "#{variant.product.name} - #{variant.name_to_display}"
    end
  end

  def unit_price
    unit_price = UnitPrice.new(variant)
    price = variant.price_with_fees(distributor, order_cycle)

    { amount: price / (unit_price.denominator || 1), unit: unit_price.unit }
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
        'add-to-cart-max-quantity-value': max_quantity,
        'add-to-cart-group-buy-value': group_buy?.to_s,
        'add-to-cart-on-hand-value': variant.on_hand,
        'add-to-cart-on-demand-value': variant.on_demand.to_s,
      },
    }
  end
end
