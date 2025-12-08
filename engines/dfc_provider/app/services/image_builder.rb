# frozen_string_literal: true

require "private_address_check"
require "private_address_check/tcpsocket_ext"

class ImageBuilder < DfcBuilder
  def self.apply(image_url, spree_product)
    return if image_url.blank?

    return if image_url == current_image_url(spree_product)

    image = ImageBuilder.import(image_url)
    spree_product.image = image if image
  end

  def self.current_image_url(spree_product)
    spree_product.image&.attachment&.blob&.custom_metadata&.fetch("origin", nil)
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
