class Api::Admin::Reports::LineItemSerializer < ActiveModel::Serializer
  attributes :id, :quantity, :max_quantity, :price, :full_name

  has_one :order, serializer: Api::Admin::IdSerializer
  has_one :product, serializer: Api::Admin::IdSerializer
end
