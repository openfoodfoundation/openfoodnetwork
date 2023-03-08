class Invoice::ShippingMethodSerializer < ActiveModel::Serializer
  attributes :name, :require_ship_address
end
