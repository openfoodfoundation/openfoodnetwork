# frozen_string_literal: true

module Api
  class ShipmentSerializer < ActiveModel::Serializer
    attributes :id, :tracking, :number, :order_id, :cost, :shipped_at, :stock_location_name, :state

    def order_id
      object.order.number
    end

    def stock_location_name
      object.stock_location.name
    end
  end
end
