# frozen_string_literal: true

require "private_address_check"
require "private_address_check/tcpsocket_ext"

class ImageBuilder < DfcBuilder
  # Works with anything that has one image: a product or a variant.
  def self.apply(image_url, imageable)
    return if image_url.blank?

    return if current_image?(image_url, imageable.image)

    image = ImageBuilder.import(image_url)
    imageable.image = image if image
  end

  # A supplied product is a variant. It shows its own image or its product's.
  # Shops list products with the product image, so a product's only variant
  # keeps using it. Other variants get their own image, leaving the shared
  # product image alone.
  def self.apply_supplied_product_image(supplied_product, variant)
    image_url = supplied_product.image
    return if current_image?(image_url, SuppliedProductBuilder.image(variant))

    if variant.image || other_variants?(variant)
      apply(image_url, variant)
    elsif supplied_product.isVariantOf.first.try(:image).blank?
      # The image of the product group takes precedence.
      apply(image_url, variant.product)
    end
  end

  def self.other_variants?(variant)
    variant.product.variants.any? { |other| other != variant }
  end

  def self.current_image?(image_url, image)
    image_url == image&.attachment&.blob&.custom_metadata&.fetch("origin", nil)
  end

  def self.import(image_link)
    url = URI.parse(image_link)
    filename = File.basename(url.path)
    metadata = { custom: { origin: image_link } }

    Spree::Image.new.tap do |image|
      PrivateAddressCheck.only_public_connections do
        io = url.open
        content_type = Marcel::MimeType.for(io)
        image.attachment.attach(io:, filename:, metadata:, content_type:)
      end
    end
  rescue StandardError
    # Any URL parsing or network error shouldn't impact the product import
    # at all. Maybe we'll add UX for error handling later.
    nil
  end
end
