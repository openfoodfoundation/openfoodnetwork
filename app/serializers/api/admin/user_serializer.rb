require 'open_food_network/last_used_address'

class Api::Admin::UserSerializer < ActiveModel::Serializer
  attributes :id, :email

  has_one :ship_address, serializer: Api::AddressSerializer
  has_one :bill_address, serializer: Api::AddressSerializer

  def ship_address
    OpenFoodNetwork::LastUsedAddress.new(object.email, object).ship_address
  end

  def bill_address
    OpenFoodNetwork::LastUsedAddress.new(object.email, object).bill_address
  end
end
