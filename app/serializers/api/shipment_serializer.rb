module Api
  class ShipmentSerializer < ActiveModel::Serializer
    attributes :number, :order_id, :stock_location_name

    def order_id
      object.order.number
    end

    def stock_location_name
      object.stock_location.name
    end
  end
end
