class Api::Admin::Reports::OrderSerializer < ActiveModel::Serializer
  attributes :id, :number

  # has_one :shop, serializer: Api::Admin::IdSerializer
  # has_one :address, serializer: Api::Admin::IdSerializer
end
