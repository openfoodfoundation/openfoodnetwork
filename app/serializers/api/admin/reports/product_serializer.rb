class Api::Admin::Reports::ProductSerializer < ActiveModel::Serializer
  attributes :id, :name

  has_one :supplier, key: :producer, serializer: Api::Admin::IdSerializer
end
