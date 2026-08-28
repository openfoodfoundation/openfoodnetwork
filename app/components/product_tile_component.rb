# frozen_string_literal: true

# A single product tile in the shopfront grid view (feature: product_grid_view).
#
# Takes a ViewData::Product whose variants have already been filtered for this shop's order
# cycle and hub, so the tile can't reach back to ActiveRecord and show variants this shop
# doesn't sell.
class ProductTileComponent < ViewComponent::Base
  NAME_SEPARATOR = " | "

  def initialize(product:, variants_in_cart:, low_stock_display:)
    @product = product
    @variants_in_cart = variants_in_cart
    @low_stock_display = low_stock_display
  end

  # A product with no variant available in this shop has no producer and no price to show.
  def render?
    product.variants.any?
  end

  private

  attr_reader :product, :variants_in_cart, :low_stock_display

  def modal_id
    "product-modal-#{product.id}"
  end

  def producer_name
    return t("components.product_tile.multiple_producers") unless product.single_producer?

    product.producers.first.name
  end

  # Single variant: {product name} | [{variant name} |] {unit or custom unit label}
  # Several:        {product name} | multiple options
  #
  # `unit_to_display` already returns the "display unit as" label when one is set and the
  # computed unit ("1kg") otherwise, so there is no need to branch on it here.
  def product_title
    safe_join(name_parts.compact_blank, NAME_SEPARATOR)
  end

  def name_parts
    unless product.single_variant?
      return [product.name, t("components.product_tile.multiple_options")]
    end

    [product.name, product.variant.display_name, product.variant.unit_to_display]
  end

  def price
    return product.variant.display_price_with_fees if product.single_variant?

    t("components.product_tile.from_price", price: product.cheapest_variant.display_price_with_fees)
  end

  # Variants come in different sizes, so a product with several has no single unit price.
  def unit_price
    return unless product.single_variant?

    helpers.unit_price_with_unit(product.variant)
  end
end
