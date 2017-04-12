class Api::Admin::Reports::AddressSerializer < ActiveModel::Serializer
  attributes :id, :phone, :address1, :address2, :city, :zipcode

  has_one :state, serializer: Api::Admin::IdNameSerializer
end
