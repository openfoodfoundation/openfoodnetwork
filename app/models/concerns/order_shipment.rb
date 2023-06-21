# frozen_string_literal: true

require 'active_support/concern'

# This module is an adapter for OFN to work with Spree 2 code.
#
# Although Spree 2 supports multiple shipments per order, in OFN we have only 1 shipment per order.
# A shipment is associated to a shipping_method through a selected shipping_rate.
# See https://github.com/openfoodfoundation/openfoodnetwork/wiki/Spree-Upgrade:-Migration-to-multiple-shipments
# for details.
#
# Methods in this module may become deprecated.
module OrderShipment
  extend ActiveSupport::Concern

  included do
    attr_accessor :manual_shipping_selection
  end

  def shipment
    shipments.first
  end

  # Returns the shipping method of the first and only shipment in the order
  #
  # @return [ShippingMethod]
  def shipping_method
    return if shipments.blank?

    shipments.first.shipping_method
  end

  # Finds the shipment's shipping_rate for the given shipping_method_id
  # and selects that shipping_rate.
  # If the selection is successful, it persists it in the database by saving the shipment.
  # If it fails, it does not clear the current shipping_method selection.
  #
  # @return [ShippingMethod] the selected shipping method, or nil if the given shipping_method_id is
  #   empty or if it cannot find the given shipping_method_id in the order
  def select_shipping_method(shipping_method_id)
    return if shipping_method_id.blank? || shipments.empty?

    shipment = shipments.first

    shipping_rate = shipment.shipping_rates.find_by(shipping_method_id: shipping_method_id)
    return unless shipping_rate

    shipment.selected_shipping_rate_id = shipping_rate.id
    shipment.shipping_method
  end
end
