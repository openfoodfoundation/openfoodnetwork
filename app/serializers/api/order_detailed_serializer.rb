# frozen_string_literal: true

module Api
  class OrderDetailedSerializer < Api::Admin::OrderSerializer
    has_one :shipping_method, serializer: Api::ShippingMethodSerializer
    has_one :ship_address, serializer: Api::AddressSerializer
    has_one :bill_address, serializer: Api::AddressSerializer

    has_many :line_items, serializer: Api::LineItemSerializer

    has_many :payments, serializer: Api::PaymentSerializer

    attributes :adjustments, :customer_id

    def adjustments
      adjustments = object.all_adjustments.where(
        adjustable_type: ["Spree::Order", "Spree::Shipment", "Spree::Payment"]
      ).order(label: :desc)
      ActiveModel::ArraySerializer.new(adjustments, each_serializer: Api::AdjustmentSerializer)
    end
  end
end
