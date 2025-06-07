# frozen_string_literal: true

require "private_address_check"
require "private_address_check/tcpsocket_ext"

class ImageImporter
  def import(url, product)
    valid_url = URI.parse(url)
    filename = File.basename(valid_url.path)
    metadata = { custom: { origin: url } }

    image = Spree::Image.create do |img|
      PrivateAddressCheck.only_public_connections do
        img.attachment.attach(io: valid_url.open, filename:, metadata:)
      end
    end
    product.image = image if image
  rescue StandardError
    # Any URL parsing or network error shouldn't impact the product import
    # at all. Maybe we'll add UX for error handling later.
    nil
  end
end
