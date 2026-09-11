# frozen_string_literal: true

class ShopVariantModalComponent < ViewComponent::Base
  def initialize(product:, variants_in_cart:, low_stock_display:)
    @product = product
    @variants_in_cart = variants_in_cart
    @low_stock_display = low_stock_display
  end

  attr_reader :product, :variants_in_cart, :low_stock_display

  private

  delegate :variants, :producers, :single_producer?, to: :product

  def product_name
    product.name
  end

  def unit_to_display(variant)
    text = ""
    text = " | " if variant.display_name.present?
    text.dup << variant.unit_to_display
  end
end
