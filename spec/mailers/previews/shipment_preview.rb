# frozen_string_literal: true

require 'open_food_network/scope_variant_to_hub'

module Spree
  class ShipmentPreview < ActionMailer::Preview
    def shipped
      ShipmentMailer.shipped_email(Shipment.last)
    end
  end
end
