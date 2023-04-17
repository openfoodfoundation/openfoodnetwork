# frozen_string_literal: true

require 'open_food_network/scope_variant_to_hub'

class ShipmentPreview < ActionMailer::Preview
  def shipped
    shipment =
      Spree::Shipment.where.not(tracking: [nil, ""]).last ||
      Spree::Shipment.last
    Spree::ShipmentMailer.shipped_email(shipment, delivery: true)
  end
end
