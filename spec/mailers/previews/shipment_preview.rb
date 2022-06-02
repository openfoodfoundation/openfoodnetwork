# frozen_string_literal: true

require 'open_food_network/scope_variant_to_hub'

module Spree
  class ShipmentPreview < ActionMailer::Preview
    def shipped
      shipment =
        Shipment.where.not(tracking: [nil, ""]).last ||
        Shipment.last
      ShipmentMailer.shipped_email(shipment)
    end
  end
end
