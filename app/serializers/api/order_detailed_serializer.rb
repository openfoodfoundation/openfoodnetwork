module Api
  class OrderDetailedSerializer < Api::Admin::OrderSerializer
    has_one :shipping_method, serializer: Api::ShippingMethodSerializer
    has_one :ship_address, serializer: Api::AddressSerializer
    has_one :bill_address, serializer: Api::AddressSerializer

    has_many :line_items, serializer: Api::LineItemSerializer
    has_many :adjustments, serializer: Api::AdjustmentSerializer

    has_many :payments, serializer: Api::PaymentSerializer
  end
end
