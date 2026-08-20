# frozen_string_literal: true

class ShopVariantOverlayComponent < ViewComponent::Base
  def initialize(variants:, variants_in_cart:, low_stock_display:)
    @variants = variants
    @variants_in_cart = variants_in_cart
    @low_stock_display = low_stock_display
  end

  attr_reader :variants, :variants_in_cart, :low_stock_display

  private

  def product_name
    variants.first.product.name
  end

  def unit_to_display(variant)
    text = ""
    text = " | " if variant.display_name.present?
    text.dup << variant.unit_to_display
  end

  def same_producers?
    return @same_producers unless @same_producers.nil?

    @same_producers = @variants.map(&:enterprise).uniq.one?
  end
end
