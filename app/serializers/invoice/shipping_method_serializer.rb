# frozen_string_literal: false

class Invoice
  class ShippingMethodSerializer < ActiveModel::Serializer
    attributes :name, :require_ship_address
  end
end
