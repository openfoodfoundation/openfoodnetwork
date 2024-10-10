# frozen_string_literal: true

require "private_address_check"
require "private_address_check/tcpsocket_ext"

class ImageBuilder < DfcBuilder
  def self.import(image_link)
    url = URI.parse(image_link)
    filename = File.basename(image_link)

    Spree::Image.new.tap do |image|
      PrivateAddressCheck.only_public_connections do
        image.attachment.attach(io: url.open, filename:)
      end
    end
  rescue StandardError
    # Any URL parsing or network error shouldn't impact the product import
    # at all. Maybe we'll add UX for error handling later.
    nil
  end
end
