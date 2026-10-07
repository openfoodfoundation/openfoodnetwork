# frozen_string_literal: true

# The list of a product's variants, each with an add to cart widget.
#
# Shared by the shopfront grid's variant modal (ShopVariantModalComponent) and the product
# page. Takes a ViewData::Product whose variants have already been filtered for the shop's
# order cycle and hub.
#
# When all variants share a producer, the caller names it once above the list and this
# component leaves it off the rows.
class ShopVariantListComponent < ViewComponent::Base
  NAME_SEPARATOR = " | "

  def initialize(product:, variants_in_cart:, low_stock_display:, cart_params: {})
    @product = product
    @variants_in_cart = variants_in_cart
    @low_stock_display = low_stock_display
    @cart_params = cart_params
  end

  private

  attr_reader :product, :variants_in_cart, :low_stock_display, :cart_params

  delegate :variants, :single_producer?, to: :product

  # The variant name is optional, so the separator belongs to the unit that follows it.
  def unit_to_display(variant)
    return variant.unit_to_display if variant.display_name.blank?

    "#{NAME_SEPARATOR}#{variant.unit_to_display}"
  end

  def producer_name(variant)
    t("components.shop_variant_list.from_producer", name: variant.producer.name)
  end
end
