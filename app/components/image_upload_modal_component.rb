# frozen_string_literal: true

class ImageUploadModalComponent < ViewComponent::Base
  def initialize(product:, image:, variant: nil)
    @product = product
    @image = image
    @variant = variant
  end

  private

  attr_reader :product, :image, :variant

  def viewable
    variant || product
  end

  def resource_name
    helpers.image_modal_resource_name(variant, product)
  end

  def preview_url
    image.persisted? ? image.url(:large) : Spree::Image.default_image_url(:large)
  end
end
