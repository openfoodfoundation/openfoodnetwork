require 'active_support/concern'

# This module is an adapter for OFN to work with Spree 2 code.
#
# Although Spree 2 supports multiple shipments per order, in OFN we have only one shipment per order.
# A shipment is associated to a shipping_method through a selected shipping_rate.
# See https://github.com/openfoodfoundation/openfoodnetwork/wiki/Spree-Upgrade:-Migration-to-multiple-shipments
# for details.
#
# Methods in this module may become deprecated.
module OrderShippingMethod
  extend ActiveSupport::Concern

  # Returns the shipping method of the first and only shipment in the order
  #
  # @return [ShippingMethod]
  def shipping_method
    return if shipments.empty?
    shipments.first.shipping_method
  end

  # Finds the shipment shipping_rate for the given shipping_method_id and selects that shipping_rate
  #
  # @return [Shipment]
  def select_shipping_method(shipping_method_id)
    return if shipping_method_id.blank? || shipments.empty?
    shipment = shipments.first

    shipping_rate = shipment.shipping_rates.find_by_shipping_method_id(shipping_method_id)
    return unless shipping_rate

    shipment.selected_shipping_rate_id=(shipping_rate.id)
    shipment.shipping_method
  end
end
