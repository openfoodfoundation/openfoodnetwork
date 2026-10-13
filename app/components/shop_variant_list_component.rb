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

  # The order of the shopfront's price breakdown.
  FEE_TYPES = %i[admin sales packing transport fundraising].freeze

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

  # Pairs of fee name and amount.
  def fee_breakdown(variant)
    FEE_TYPES.filter_map do |fee_type|
      amount = variant.fees[fee_type]
      [variant.fee_names[fee_type], amount] if amount
    end
  end

  def display_money(amount)
    Spree::Money.new(amount).to_s
  end
end
