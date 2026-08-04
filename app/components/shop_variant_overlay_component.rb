# frozen_string_literal: true

class ShopVariantOverlayComponent < ViewComponent::Base
  def initialize(variants:, distributor:, order_cycle:, enterprise_fee_calculator:,
                 variants_in_cart:, low_stock_display:, presenter_class: VariantPresenter)
    @variants = variants.map { |v|
      presenter_class.new(variant: v, distributor:, order_cycle:, enterprise_fee_calculator:)
    }

    @variants_in_cart = variants_in_cart
    @low_stock_display = low_stock_display
  end

  attr_reader :variants, :variants_in_cart, :low_stock_display

  private

  def producers
    @producers ||= @variants.map(&:enterprise).uniq
  end

  def same_producers?
    producers.length == 1
  end
end
