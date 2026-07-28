# frozen_string_literal: true

class ShopVariantOverlayComponent < ViewComponent::Base
  def initialize(variants:)
    @variants = variants
  end

  attr_reader :variants
end
