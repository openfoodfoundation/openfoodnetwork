# frozen_string_literal: true

module Api
  class ShipmentSerializer < ActiveModel::Serializer
    attributes :id, :tracking, :number, :order_id, :cost, :shipped_at, :state

    def order_id
      object.order.number
    end
  end
end
